# Scripts

A collection of useful shell scripts for development and system management.

## Scripts

### 1. `aicommit.sh` - AI-Powered Git Commit Message Generator

An intelligent script that uses OpenAI's API to generate conventional commit messages based on your git changes.

#### Features

- 🤖 Automatically generates commit messages following [Conventional Commits](https://www.conventionalcommits.org/) specification
- 📝 Analyzes staged, unstaged, and untracked files
- ✏️ Allows review and editing before committing
- 🚀 Optionally pushes to remote repository
- ⚡ Non-interactive mode for automation

#### Requirements

- `jq` - JSON processor (`sudo apt-get install jq` or `brew install jq`)
- `curl` - HTTP client (usually pre-installed)
- `OPENAI_API_KEY` environment variable set
- Git repository

#### One-Liner Installation

```bash
# Install and set up aicommit as a git command
curl -fsSL https://raw.githubusercontent.com/Moussa-M/scripts/main/aicommit.sh | sudo tee /usr/local/bin/git-aicommit > /dev/null && sudo chmod +x /usr/local/bin/git-aicommit

# Set your OpenAI API key (add to ~/.zshrc or ~/.bashrc for persistence)
export OPENAI_API_KEY='your-api-key-here'
echo 'export OPENAI_API_KEY="your-api-key-here"' >> ~/.zshrc  # or ~/.bashrc
```

#### Usage

After installation, use it directly as a git command:

```bash
# Basic usage (commits and pushes by default)
git aicommit

# Commit only, don't push
git aicommit --no-push
# or
git aicommit -n

# Non-interactive mode (auto-accept generated message)
git aicommit -y
# or
git aicommit --yes

# Show help
git aicommit --help
```

#### How It Works

1. Analyzes all git changes (staged, unstaged, untracked)
2. Sends diff to OpenAI API with instructions for conventional commits
3. Generates a commit message with type, scope, and description
4. Shows the message for review
5. Allows editing or auto-accepts (with `-y` flag)
6. Commits the changes
7. Optionally pushes to remote (unless `--no-push` is used)

#### Commit Message Format

The script generates messages following Conventional Commits:

```
<type>(<scope>): <description>

- Bullet point details
- More details about changes
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

#### Examples

```bash
# Stage some changes
git add file1.py file2.js

# Generate and commit with AI (non-interactive)
git aicommit -y

# Output example:
# AI‑generated commit message:
# ----------------------------------------
# feat(api): add user authentication endpoints
#
# - Implement login and register endpoints
# - Add JWT token generation
# - Include password hashing
# ----------------------------------------
```

---

### 2. `install-raspi-theme.sh` - Raspi Zsh Theme Installer

Installs a clean and colorful Zsh theme for Oh My Zsh with customizable prompt elements.

#### Features

- 🎨 Clean and minimal design with raspberry pink accents
- 🔧 Highly customizable prompt format
- 📦 Shows username, hostname, network interface/IP, directory
- 🐍 Displays conda and virtualenv environments
- 🌿 Shows active git branch when in a repository
- ⚡ Fast and lightweight

#### Requirements

- `zsh` installed
- `git` installed
- Oh My Zsh installed

#### Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/Moussa-M/scripts/main/install-raspi-theme.sh | bash
```

#### Custom Format

The theme supports a flexible format system. Default: `u@h [i:p] d (c) (v) (g)`

**Format Elements:**
- `u@h` - username@hostname
- `[i:p]` - [interface:ip] - network interface and IP address
- `d` - directory/path
- `(c)` - conda environment (if active)
- `(v)` - virtualenv (if active)
- `(g)` - git branch (if in a git repository)

**Examples:**

```bash
# Full format (default)
./install-raspi-theme.sh

# Custom format: minimal
./install-raspi-theme.sh -f "u@h d"

# Custom format: with IP only
./install-raspi-theme.sh -f "u@h [p] d"

# Exclude conda and virtualenv
./install-raspi-theme.sh -ex cv

# Custom format with exclusions
./install-raspi-theme.sh -f "u@h [i:p] d" -ex i
```

**Command Line Options:**
- `-f FORMAT` or `--format=FORMAT` - Specify custom format string
- `-ex EXCLUDE` or `--exclude=EXCLUDE` - Exclude elements from format
- `-h` or `--help` - Show help message

After installation, reload your shell:
```bash
source ~/.zshrc
```

---

## Quick Installation

### aicommit.sh

```bash
# One-liner install as git command
curl -fsSL https://raw.githubusercontent.com/Moussa-M/scripts/main/aicommit.sh | sudo tee /usr/local/bin/git-aicommit > /dev/null && sudo chmod +x /usr/local/bin/git-aicommit

# Set OpenAI API key
export OPENAI_API_KEY='your-api-key-here'
echo 'export OPENAI_API_KEY="your-api-key-here"' >> ~/.zshrc  # or ~/.bashrc
```

### install-raspi-theme.sh

```bash
# One-liner install (already available)
curl -fsSL https://raw.githubusercontent.com/Moussa-M/scripts/main/install-raspi-theme.sh | bash
```

## GitHub Pages

This repository has a GitHub Pages site that automatically builds from the README. Visit the live site at:

**https://moussa-m.github.io/scripts/**

The site is automatically updated whenever changes are pushed to the `main` branch via GitHub Actions.

## License

These scripts are provided as-is for personal use.

## Author

Created by [Moussa Mokhtari](https://moussamokhtari.com)

## Contributing

Feel free to submit issues or pull requests if you have improvements or bug fixes.

