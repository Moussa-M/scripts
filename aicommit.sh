#!/usr/bin/env bash

# ai_commit.sh
# ----------------------------------------------------------------------
# Generates a Conventional‑Commit message with OpenAI, lets the user
# review/edit it, commits the changes and (optionally) pushes to the
# remote repository.
#
# Usage:
#   ./ai_commit.sh [--no-push|-n]        # commit and push (default)
#   ./ai_commit.sh --no-push             # commit only, do NOT push
#   ./ai_commit.sh -y|--yes              # non-interactive; auto-use generated message
#   ./ai_commit.sh -h|--help             # show this help
# ----------------------------------------------------------------------

set -euo pipefail

# ---------- Argument handling ----------
NO_PUSH=false
ASSUME_YES=false

while (( "$#" )); do
    case "$1" in
        --no-push|-n)  NO_PUSH=true ;;
        --yes|-y)      ASSUME_YES=true ;;
        -h|--help)
            echo "ai_commit.sh – generate an AI commit message, commit and push."
            echo
            echo "Options:"
            echo "  --no-push, -n   Do not push the commit to the remote."
            echo "  --yes, -y       Assume yes: auto-use the generated message and skip prompts."
            echo "  -h, --help      Show this help message."
            exit 0
            ;;
        *)  # unknown option – ignore (allows future positional args)
            echo "Warning: unknown option \"$1\" ignored."
            ;;
    esac
    shift
done

# ---------- Repository checks ----------
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "Error: Not inside a git repository."
    exit 1
fi

# ---------- Environment checks ----------
if [[ -z "${OPENAI_API_KEY:-}" ]]; then
    echo "Error: OPENAI_API_KEY environment variable is not set."
    echo "Please set it with: export OPENAI_API_KEY='your-api-key'"
    exit 1
fi

if ! command -v jq &>/dev/null; then
    echo "Error: jq is not installed. Please install it first."
    echo "Ubuntu/Debian: sudo apt-get install jq"
    echo "macOS: brew install jq"
    exit 1
fi

# ---------- Constants ----------
MAX_CHAR_LIMIT=20000          # Approximate token limit accounting for OpenAI's token limit
MAX_FILE_CHAR_LIMIT=2000      # Character limit per file content
MAX_DIFF_LINES=100            # Maximum number of diff lines per file

# ---------- Helper functions ----------
truncate_text() {
    local text="$1"
    local max_chars=$2

    if (( ${#text} > max_chars )); then
        local truncated="${text:0:$((max_chars-50))}"
        truncated+="\n... [truncated - $(( (${#text} - max_chars) / 1000 ))K chars omitted] ...\n"
        echo -e "$truncated"
    else
        echo -e "$text"
    fi
}

truncate_diff() {
    local diff_output="$1"
    local max_lines=$2

    local line_count
    line_count=$(echo "$diff_output" | wc -l)

    if (( line_count > max_lines )); then
        local half=$((max_lines / 2))
        local first_part last_part
        first_part=$(echo "$diff_output" | head -n "$half")
        last_part=$(echo "$diff_output" | tail -n "$half")
        echo -e "$first_part"
        echo "... [truncated - $((line_count - max_lines)) lines omitted] ..."
        echo -e "$last_part"
    else
        echo -e "$diff_output"
    fi
}

# ---------- Gather diff ----------
get_all_changes() {
    local changes="" total_chars=0 truncated=false

    # Summary header
    changes+="=== Summary of Changes ===\n"

    # ---- Staged ----
    local staged=$(git diff --cached --name-status)
    if [[ -n $staged ]]; then
        changes+="=== Staged Changes ===\n"
        changes+="Files changed:\n$staged\n\n"

        local staged_diff=$(git diff --cached --color=never)
        local staged_diff_truncated=$(truncate_diff "$staged_diff" $MAX_DIFF_LINES)
        changes+="Detailed changes:\n$staged_diff_truncated\n\n"
        total_chars=$((total_chars + ${#staged_diff_truncated}))
    fi

    # ---- Unstaged ----
    if (( total_chars < MAX_CHAR_LIMIT * 3 / 4 )); then
        local unstaged=$(git diff --name-status)
        if [[ -n $unstaged ]]; then
            changes+="=== Unstaged Changes ===\n"
            changes+="Files changed:\n$unstaged\n\n"

            local unstaged_diff=$(git diff --color=never)
            local unstaged_diff_truncated=$(truncate_diff "$unstaged_diff" $MAX_DIFF_LINES)
            changes+="Detailed changes:\n$unstaged_diff_truncated\n\n"
            total_chars=$((total_chars + ${#unstaged_diff_truncated}))
        fi
    else
        truncated=true
        changes+="\n... [Some changes omitted due to size limitations] ...\n\n"
    fi

    # ---- Untracked ----
    if (( total_chars < MAX_CHAR_LIMIT * 7 / 8 )) && ! $truncated; then
        local untracked=$(git ls-files --others --exclude-standard)
        if [[ -n $untracked ]]; then
            changes+="=== Untracked Files ===\n"
            local file_limit=5 count=0
            while IFS= read -r file && (( count < file_limit )) && (( total_chars < MAX_CHAR_LIMIT )); do
                [[ -f $file ]] || continue
                ((count++))
                changes+="New file: $file\n"
                if file "$file" | grep -q "text"; then
                    local content truncated_content
                    content=$(cat "$file")
                    truncated_content=$(truncate_text "$content" $MAX_FILE_CHAR_LIMIT)
                    changes+="Content:\n$truncated_content\n\n"
                    total_chars=$((total_chars + ${#truncated_content}))
                else
                    changes+="(Binary file)\n\n"
                fi
                (( total_chars > MAX_CHAR_LIMIT * 9 / 10 )) && break
            done <<< "$untracked"

            local total_untracked
            total_untracked=$(echo "$untracked" | wc -l)
            (( total_untracked > file_limit )) && \
                changes+="Note: Only showing $count of $total_untracked untracked files\n"
        fi
    else
        changes+="\n... [Untracked files omitted due to size limitations] ...\n\n"
    fi

    # Final truncation safeguard
    if (( ${#changes} > MAX_CHAR_LIMIT )); then
        truncate_text "$changes" $MAX_CHAR_LIMIT
    else
        echo -e "$changes"
    fi
}

# ---------- Main flow ----------
FULL_DIFF=$(get_all_changes)

if [[ -z $FULL_DIFF ]]; then
    echo "No changes detected."
    exit 0
fi

echo "Analyzing changes and generating commit message..."

# Build JSON payload (properly escaped via jq)
JSON_PAYLOAD=$(jq -n \
    --arg content "You are a helpful assistant that generates git commit messages following the Conventional Commits specification. Focus on the actual code changes to determine the type and scope. Keep the message concise but complete, under 50 characters for the first line if possible." \
    --arg prompt "Generate a concise and descriptive git commit message for the following changes.
Follow the conventional commits specification (https://www.conventionalcommits.org/).
Use one of these types: feat, fix, docs, style, refactor, test, chore.

Rules:
1. Format first line as: <type>(<scope>): <description>
2. The first line should be under 50 characters if possible
3. After the first line, add a blank line and then bullet points for details
4. Each bullet point should start with a hyphen
5. Keep bullet points short and clear
6. Focus on WHAT changed and WHY, not HOW

Here are the changes:

$FULL_DIFF" \
    '{
        model: "gpt-4o-mini",
        messages: [
            {role: "system",   content: $content},
            {role: "user",     content: $prompt}
        ],
        temperature: 0.7,
        max_tokens: 2048
    }')

# Call the OpenAI API
RESPONSE=$(curl -s https://api.openai.com/v1/chat/completions \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    -d "$JSON_PAYLOAD")

# ---- API error handling ----
if echo "$RESPONSE" | jq -e '.error' >/dev/null; then
    ERROR_MSG=$(echo "$RESPONSE" | jq -r '.error.message')
    echo "Error from OpenAI API: $ERROR_MSG"
    if [[ $ERROR_MSG == *tokens* || $ERROR_MSG == *max* || $ERROR_MSG == *too* ]]; then
        echo "The diff is likely too large. Reduce changes or adjust MAX_CHAR_LIMIT."
    fi
    exit 1
fi

# Extract the generated commit message
GENERATED_MSG=$(echo "$RESPONSE" | jq -r '.choices[0].message.content')
GENERATED_MSG=$(echo "$GENERATED_MSG" | sed '/^```/d')   # strip possible fences

# ---- User review ----
echo -e "\nAI‑generated commit message:"
echo "--------------------------------"
echo -e "$GENERATED_MSG"
echo "--------------------------------"

if $ASSUME_YES; then
    FINAL_MSG="$GENERATED_MSG"
else
    read -p "Use this commit message? [Y/n/e] (Y = use, n = abort, e = edit): " choice
    choice=$(echo "$choice" | tr '[:upper:]' '[:lower:]')

    case "$choice" in
        n) echo "Commit aborted."; exit 0 ;;
        e)
            TMPFILE=$(mktemp /tmp/commit_msg.XXXXXX)
            echo "$GENERATED_MSG" > "$TMPFILE"
            ${EDITOR:-nano} "$TMPFILE"
            FINAL_MSG=$(<"$TMPFILE")
            rm -f "$TMPFILE"
            ;;
        *) FINAL_MSG="$GENERATED_MSG" ;;
    esac
fi

# ---- Final confirmation ----
echo -e "\nFinal commit message:"
echo "--------------------------------"
echo -e "$FINAL_MSG"
echo "--------------------------------"
if ! $ASSUME_YES; then
    read -p "Press Enter to commit (Ctrl+C to abort) … "
fi

# ---- Commit ----
git add -A
git commit -m "$FINAL_MSG"

echo -e "\n✅ Changes committed successfully!"

# ---- Optional push ----
if ! $NO_PUSH; then
    echo "Pushing to remote..."
    # Push to the current branch's upstream (if set); otherwise fall back to origin HEAD
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
    if git rev-parse --abbrev-ref "@{u}" &>/dev/null; then
        # Upstream exists – use default push (preserves upstream config)
        if git push; then
            echo "🚀 Push completed."
        else
            echo "⚠️ Push failed."
            exit 1
        fi
    else
        # No upstream configured – push to origin explicitly
        if git push origin "$CURRENT_BRANCH"; then
            echo "🚀 Push completed."
        else
            echo "⚠️ Push failed."
            exit 1
        fi
    fi
else
    echo "⚡️ Push skipped due to --no-push flag."
fi

# ---- History logging (optional) ----
# Append the exact command used for future reference.
echo "git commit -m \"$FINAL_MSG\"" >> ~/.history

exit 0