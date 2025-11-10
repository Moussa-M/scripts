#!/usr/bin/env bash
# ------------------------------------------------------------------
# Install Raspi Zsh Theme — clean and simple
# ------------------------------------------------------------------
# Usage:
#   Quick install:
#     # Requirements  
#     # apt install zsh
#     # apt install git
#     # sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
#     curl -fsSL https://raw.githubusercontent.com/Moussa-M/scripts/main/install-raspi-theme.sh | bash
#
#   Custom format:
#     curl -fsSL https://raw.githubusercontent.com/Moussa-M/scripts/main/install-raspi-theme.sh | bash -s -- -f "u@h d"
#     curl -fsSL https://raw.githubusercontent.com/Moussa-M/scripts/main/install-raspi-theme.sh | bash -s -- -ex i
#     ./install-raspi-theme.sh -f "u@h [i:p] d" -ex cv
#
# Prompt format:  u@h [i:p] d (c) (v) (g)
#
# Format elements:
#   u@h - username@hostname
#   [i:p] - [interface:ip]
#   d - directory/path
#   (c) - (conda env)
#   (v) - (virtualenv)
#   (g) - (git branch)
#
# Default: u@h [i:p] d (c) (v) (g)
#
# Examples:
#   -f "u@h [i:p] d (c) (v) (g)"   Full format (default)
#   -f "u@h [p] d"                 Username@hostname, IP, directory
#   -f "u@h d"                     Minimal: username@hostname, directory
#   -ex cv                         Exclude conda and virtualenv from default
#   -f "u@h [i:p] d" -ex i         Full but exclude interface
#   -f "u@h u@h"                   Duplicate: user@host user@host
# ------------------------------------------------------------------

set -e

# Default format: full
FORMAT="u@h [i:p] d (c) (v) (g)"
EXCLUDE=""

while [[ $# -gt 0 ]]; do
  case $1 in
    -f)
      if [[ -z "$2" || "$2" == -* ]]; then
        echo "Error: -f requires a format argument"
        exit 1
      fi
      FORMAT="$2"
      shift 2
      ;;
    --format=*)
      FORMAT="${1#*=}"
      shift
      ;;
    -ex)
      # Allow empty exclusion or missing argument
      if [[ -n "$2" && "$2" != -* ]]; then
        EXCLUDE="$2"
        shift 2
      else
        EXCLUDE=""
        shift
      fi
      ;;
    --exclude=*)
      EXCLUDE="${1#*=}"
      shift
      ;;
    --help|-h)
      echo "Usage: $0 [-f FORMAT] [-ex EXCLUDE]"
      echo ""
      echo "Prompt format:  u@h [i:p] d (c) (v) (g)"
      echo ""
      echo "Format elements:"
      echo "  u@h   - username@hostname"
      echo "  [i:p] - [interface:ip]"
      echo "  d     - directory/path"
      echo "  (c)   - (conda env)"
      echo "  (v)   - (virtualenv)"
      echo "  (g)   - (git branch)"
      echo ""
      echo "Examples:"
      echo "  -f \"u@h [i:p] d (c) (v) (g)\"   Full format (default)"
      echo "  -f \"u@h [p] d\"                 Username@hostname, IP, directory"
      echo "  -f \"u@h d\"                     Minimal: username@hostname, directory"
      echo "  -ex cv                         Exclude conda and virtualenv"
      echo "  -f \"u@h [i:p] d\" -ex i         Full but exclude interface"
      echo "  -f \"u@h u@h\"                   Duplicate: user@host user@host"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

# Parse format string
SHOW_USER=false
SHOW_HOST=false
SHOW_INTERFACE=false
SHOW_IP=false
SHOW_DIR=false
SHOW_CONDA=false
SHOW_VENV=false
SHOW_GIT=false

[[ "$FORMAT" == *"u"* ]] && SHOW_USER=true
[[ "$FORMAT" == *"h"* ]] && SHOW_HOST=true
[[ "$FORMAT" == *"i"* ]] && SHOW_INTERFACE=true
[[ "$FORMAT" == *"p"* ]] && SHOW_IP=true
[[ "$FORMAT" == *"d"* ]] && SHOW_DIR=true
[[ "$FORMAT" == *"c"* ]] && SHOW_CONDA=true
[[ "$FORMAT" == *"v"* ]] && SHOW_VENV=true
[[ "$FORMAT" == *"g"* ]] && SHOW_GIT=true

# Apply exclusions (take priority over format)
[[ "$EXCLUDE" == *"u"* ]] && SHOW_USER=false
[[ "$EXCLUDE" == *"h"* ]] && SHOW_HOST=false
[[ "$EXCLUDE" == *"i"* ]] && SHOW_INTERFACE=false
[[ "$EXCLUDE" == *"p"* ]] && SHOW_IP=false
[[ "$EXCLUDE" == *"d"* ]] && SHOW_DIR=false
[[ "$EXCLUDE" == *"c"* ]] && SHOW_CONDA=false
[[ "$EXCLUDE" == *"v"* ]] && SHOW_VENV=false
[[ "$EXCLUDE" == *"g"* ]] && SHOW_GIT=false

THEME_DIR="$HOME/.oh-my-zsh/custom/themes"
THEME_FILE="$THEME_DIR/raspi.zsh-theme"

# Build the actual format string based on what's enabled (preserve order from FORMAT)
ACTUAL_FORMAT=""
for (( i=0; i<${#FORMAT}; i++ )); do
  char="${FORMAT:$i:1}"
  case "$char" in
    u) $SHOW_USER && ACTUAL_FORMAT="${ACTUAL_FORMAT}u" ;;
    h) $SHOW_HOST && ACTUAL_FORMAT="${ACTUAL_FORMAT}h" ;;
    i) $SHOW_INTERFACE && ACTUAL_FORMAT="${ACTUAL_FORMAT}i" ;;
    p) $SHOW_IP && ACTUAL_FORMAT="${ACTUAL_FORMAT}p" ;;
    d) $SHOW_DIR && ACTUAL_FORMAT="${ACTUAL_FORMAT}d" ;;
    c) $SHOW_CONDA && ACTUAL_FORMAT="${ACTUAL_FORMAT}c" ;;
    v) $SHOW_VENV && ACTUAL_FORMAT="${ACTUAL_FORMAT}v" ;;
    g) $SHOW_GIT && ACTUAL_FORMAT="${ACTUAL_FORMAT}g" ;;
  esac
done

echo "📦 Installing Raspi Zsh Theme..."
mkdir -p "$THEME_DIR"

cat > "$THEME_FILE" <<EOF
# raspi.zsh-theme — clean and colorful prompt
#
# Format: $ACTUAL_FORMAT
# Displays: u@h [i:p] d (c) (v) (g)
#   u@h   - username@hostname
#   [i:p] - [interface:ip]
#   d     - directory/path
#   (c)   - (conda env)
#   (v)   - (virtualenv)
#   (g)   - (git branch)

export VIRTUAL_ENV_DISABLE_PROMPT=1
export CONDA_CHANGEPS1=false
setopt PROMPT_SUBST

conda_info() { [ -n "\$CONDA_DEFAULT_ENV" ] && echo "(\$CONDA_DEFAULT_ENV) "; }
virtualenv_info() { [ -n "\$VIRTUAL_ENV" ] && echo "(\$(basename "\$VIRTUAL_ENV")) "; }
git_branch() {
  local branch
  branch=\$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  [ -n "\$branch" ] && echo "(\$branch) "
}
box_name() { echo "\${SHORT_HOST:-\$HOST}"; }
local_ip() {
  local ip iface result
  read -r ip iface < <(ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) {if(\$i=="src") ip=\$(i+1); if(\$i=="dev") dev=\$(i+1)}} END {print ip, dev}')

  if [ -n "\$iface" ]; then
    if [[ "\$iface" =~ ^(tun|wg) ]]; then
      result="%F{226}\$iface%F{48}"
    else
      result="\$iface"
    fi

    if $SHOW_INTERFACE && $SHOW_IP; then
      echo "\$result:\$ip"
    elif $SHOW_INTERFACE; then
      echo "\$result"
    elif $SHOW_IP; then
      echo "\$ip"
    fi
  elif $SHOW_IP && [ -n "\$ip" ]; then
    echo "\$ip"
  fi
}

# Clear screen once on startup
if [ -z "\$__RASPI_PROMPT_INIT" ]; then
  clear
  export __RASPI_PROMPT_INIT=1
fi

# Cursor: blinking block in raspberry pink
echo -ne '\e[1 q\e]12;#ff0087\a'

# Build prompt dynamically based on format string
FORMAT_STR="$ACTUAL_FORMAT"
PROMPT_PARTS=""

for (( i=0; i<\${#FORMAT_STR}; i++ )); do
  char="\${FORMAT_STR:\$i:1}"
  next_char="\${FORMAT_STR:\$((i+1)):1}"
  prev_char="\${FORMAT_STR:\$((i-1)):1}"

  # Add space before element if not part of a group (u@h, i:p, or env indicators)
  if [ -n "\$PROMPT_PARTS" ]; then
    # Don't add space if previous was 'u' and current is 'h' (they're connected by @)
    # Don't add space if current is 'p' and prev is 'i' (they're in brackets together)
    # Don't add space if current is 'c', 'v', or 'g' and previous was also 'c', 'v', or 'g'
    if [[ ! ( "\$prev_char" == "u" && "\$char" == "h" ) && \
          ! ( "\$prev_char" == "i" && "\$char" == "p" ) && \
          ! ( "\$prev_char" == "p" && "\$char" == "i" ) && \
          ! ( ( "\$prev_char" == "c" || "\$prev_char" == "v" || "\$prev_char" == "g" ) && ( "\$char" == "c" || "\$char" == "v" || "\$char" == "g" ) ) ]]; then
      PROMPT_PARTS="\${PROMPT_PARTS} "
    fi
  fi

  case "\$char" in
    u)
      PROMPT_PARTS="\${PROMPT_PARTS}%F{198}%n%f"
      # Add @ if next char is h
      [[ "\$next_char" == "h" ]] && PROMPT_PARTS="\${PROMPT_PARTS}@"
      ;;
    h)
      PROMPT_PARTS="\${PROMPT_PARTS}%F{39}\\\$(box_name)%f"
      ;;
    i|p)
      # Handle network info (interface and/or IP)
      PROMPT_PARTS="\${PROMPT_PARTS}%F{48}[\\\$(local_ip)]%f"
      # Skip next char if it's also network-related to avoid duplication
      if [[ "\$char" == "i" && "\$next_char" == "p" ]] || [[ "\$char" == "p" && "\$next_char" == "i" ]]; then
        ((i++))
      fi
      ;;
    d) PROMPT_PARTS="\${PROMPT_PARTS}%F{39}%~%f" ;;
    c) PROMPT_PARTS="\${PROMPT_PARTS}%F{244}\\\$(conda_info)%f" ;;
    v) PROMPT_PARTS="\${PROMPT_PARTS}%F{244}\\\$(virtualenv_info)%f" ;;
    g) PROMPT_PARTS="\${PROMPT_PARTS}%F{244}\\\$(git_branch)%f" ;;
  esac
done

# Two-line prompt
PROMPT="\${PROMPT_PARTS}
%F{198}➜%f "

RPROMPT=""
ZSH_THEME_GIT_PROMPT_PREFIX=""
ZSH_THEME_GIT_PROMPT_SUFFIX=""
ZSH_THEME_GIT_PROMPT_DIRTY=""
ZSH_THEME_GIT_PROMPT_CLEAN=""
EOF

echo "✅ Theme written to $THEME_FILE"

# Update .zshrc to use raspi theme
if ! grep -q 'ZSH_THEME="raspi"' "$HOME/.zshrc" 2>/dev/null; then
  echo 'Updating ~/.zshrc to use raspi theme...'
  sed -i 's/^ZSH_THEME=.*/ZSH_THEME="raspi"/' "$HOME/.zshrc" 2>/dev/null \
    || echo 'ZSH_THEME="raspi"' >> "$HOME/.zshrc"
fi

echo "✨ Installation complete."

if [ -n "$EXCLUDE" ]; then
  echo "📋 Format: $FORMAT (excluded: $EXCLUDE) = $ACTUAL_FORMAT"
else
  echo "📋 Format: $ACTUAL_FORMAT"
fi

# Show active elements in the order they appear in ACTUAL_FORMAT
if [ -n "$ACTUAL_FORMAT" ]; then
  echo ""
  echo "Prompt elements:"
  for (( i=0; i<${#ACTUAL_FORMAT}; i++ )); do
    char="${ACTUAL_FORMAT:$i:1}"
    case "$char" in
      u) echo "  ✓ username (u)" ;;
      h) echo "  ✓ hostname (h)" ;;
      i) echo "  ✓ interface (i)" ;;
      p) echo "  ✓ IP address (p)" ;;
      d) echo "  ✓ directory (d)" ;;
      c) echo "  ✓ conda env (c)" ;;
      v) echo "  ✓ virtualenv (v)" ;;
      g) echo "  ✓ git branch (g)" ;;
    esac
  done
else
  echo ""
  echo "⚠️  Warning: No prompt elements enabled (empty format)"
fi

echo ""
echo "➡️  Run:  source ~/.zshrc"
