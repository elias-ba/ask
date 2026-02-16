<p align="left">
  <img src="assets/ask_3.png" alt="ask" width="50" height="50">
  <strong style="font-size: 2.5rem;">ask.</strong> <em>don't grep. don't awk. just ask</em>
</p>

ask is an AI-powered CLI tool for developers who live in the terminal. It brings multi-provider LLM support, agent capabilities, and shell-native intelligence to your fingertips.

## Why ask?

Unlike generic LLM CLIs, ask is built for **shell power users**:

- **Generates reusable bash functions** - Not just answers, but tools
- **Agent mode** - Executes safe plans with your approval
- **Shell-native** - Works perfectly with pipes and Unix philosophy
- **Context-aware** - Understands git repos, recent commands, system state
- **Fast & streaming** - Real-time responses as you type
- **Multi-provider** - Anthropic, OpenAI, Google Gemini, OpenRouter, DeepSeek, and Ollama (local)
- **Structured output** - `--json`, `--csv`, `--md`, `--raw` for pipeline composability
- **Pure bash** - No Python, Node, or other runtimes needed

## Installation

### Quick Install

```bash
# Download
curl -o ask https://raw.githubusercontent.com/elias-ba/ask/main/ask
chmod +x ask

# Move to PATH
sudo mv ask /usr/local/bin/

# Or for user-only install
mv ask ~/.local/bin/
```

### Using Git

```bash
git clone https://github.com/elias-ba/ask.git
cd ask
chmod +x ask
sudo ln -s "$(pwd)/ask" /usr/local/bin/ask
```

### Dependencies

- `curl` - For API calls
- `jq` - For JSON processing
- Optional: `glow` or `bat` for prettier output

Install on Ubuntu/Debian:

```bash
sudo apt-get install curl jq
```

Install on macOS:

```bash
brew install curl jq
```

### Uninstall

To completely remove ask from your system:

```bash
# Remove the binary
sudo rm /usr/local/bin/ask
# Or if installed to user directory
rm ~/.local/bin/ask

# Remove configuration and saved functions
rm -rf ~/.config/ask/

# Remove cache and history
rm -rf ~/.cache/ask/
```

## Setup

### Quick Setup (Recommended)

ask manages API keys for you:

```bash
# Set your API key (it will prompt you securely)
ask keys set anthropic

# Or for other providers
ask keys set openai
ask keys set openrouter
ask keys set google
ask keys set deepseek

# List your configured keys
ask keys list

# Check where keys are stored
ask keys path
```

Keys are stored securely in `~/.config/ask/keys.env` with 600 permissions (readable only by you).

### Alternative: Environment Variables

If you prefer environment variables:

```bash
# Anthropic (recommended)
export ANTHROPIC_API_KEY='sk-ant-...'

# OpenAI
export OPENAI_API_KEY='sk-...'

# Google Gemini
export GOOGLE_API_KEY='...'

# OpenRouter
export OPENROUTER_API_KEY='sk-or-...'

# DeepSeek
export DEEPSEEK_API_KEY='...'

# Ollama (optional, defaults to http://localhost:11434)
export OLLAMA_HOST='http://localhost:11434'
```

Add to your `~/.bashrc` or `~/.zshrc` to persist.

### Get API Keys

- **Anthropic**: <https://console.anthropic.com/>
- **OpenAI**: <https://platform.openai.com/api-keys>
- **Google Gemini**: <https://aistudio.google.com/apikey>
- **OpenRouter**: <https://openrouter.ai/keys>
- **DeepSeek**: <https://platform.deepseek.com/api_keys>

#### Ollama (Local Models)

Ollama requires no API key. Install it and pull a model:

```bash
# Install Ollama (https://ollama.com)
# Then pull a model
ollama pull llama3.2

# Use with ask
ask -L "your question"
```

## Usage

### Quick Questions

```bash
# Simple queries
ask "how do I find large files?"

# Pipe input
git log --oneline | ask "summarize recent changes"

# Debug errors
cat error.log | ask "what's causing these errors?"
```

### Agent Mode

Let ask execute tasks for you:

```bash
# Optimize images
ask --agent "find and optimize all PNG files in ./images"

# Clean up
ask --agent "remove docker containers older than 30 days"

# Dry run first
ask --agent --dry-run "reorganize these files by type"
```

### Generate Shell Functions

Create reusable tools:

```bash
# Generate a function
ask --fn parse_nginx "extract 500 errors from nginx access logs"

# ask will generate, validate, and save:
# parse_nginx() {
#   grep " 500 " "$1" | awk '{print $1, $7}' | sort | uniq -c
# }

# Use it immediately
source ~/.config/ask/functions.sh
parse_nginx /var/log/nginx/access.log
```

### Git Helpers

```bash
# Generate semantic commit messages
git add .
ask commit

# Review PR
ask pr-review

# Explain what changed
git diff main | ask "explain these changes"
```

### Interactive Mode

```bash
ask
# Starts interactive chat with:
# - Conversation history
# - Context awareness
# - Multi-turn dialogue
# - Special commands (/help, /clear, etc.)
```

## Special Modes

### Context-Aware Queries

```bash
# Minimal context (pwd, date)
ask --context min "what's in this directory?"

# Auto context (git, recent commands)
ask --context auto "debug this error"

# Full context (env, history, system)
ask --context full "why did that command fail?"
```

### Local Models (Ollama)

```bash
# Use a local model
ask -L "explain this error"

# List installed local models
ask -L --list-models

# Use a specific local model
ask -L -m mistral "your question"

# Custom Ollama host
OLLAMA_HOST=http://192.168.1.10:11434 ask -L "hello"
```

### Model Selection

```bash
# List available models
ask --list-models

# Use specific model
ask -m gpt-4o "write a poem"

# Switch provider
ask -p openai "your question"
```

### Structured Output

```bash
# JSON with metadata envelope (validated with jq)
ask --json "list HTTP status codes" | jq '.response'

# CSV with headers
ask --csv "compare python vs javascript" > comparison.csv

# Clean Markdown
ask --md "explain REST APIs"

# Raw text, no ANSI codes (useful in scripts)
ask --raw "generate a UUID" | pbcopy
```

JSON and CSV automatically disable streaming to validate and post-process the full response.

### Streaming Control

```bash
# Enable streaming (default)
ask -s "long explanation"

# Disable for parseable output
ask -n "output json" | jq .
```

## Interactive Commands

Inside `ask` interactive mode:

| Command                      | Description                |
| ---------------------------- | -------------------------- |
| `/clear`                     | Clear conversation history |
| `/save`                      | Save conversation to file  |
| `/load`                      | Load previous conversation |
| `/models`                    | List available models      |
| `/switch [provider] [model]` | Switch provider/model      |
| `/context [level]`           | Set context level          |
| `/help`                      | Show help                  |
| `/exit` or `/quit`           | Exit                       |

## Configuration

ask uses XDG Base Directory spec:

```bash
~/.config/ask/           # Configuration
  └── functions.sh       # Generated functions

~/.cache/ask/            # Cache & history
  ├── history.jsonl      # Conversation history
  └── context.json       # Context cache
```

## Examples

### Pipeline Integration

```bash
# Analyze logs
tail -f /var/log/app.log | ask "alert me to errors"

# Process data
cat users.csv | ask "find duplicate emails"

# Code review
git diff | ask "suggest improvements"
```

### Development Workflow

```bash
# Debug
ask "why is this segfaulting?" < debug.log

# Test generation
ask --fn test_auth "generate pytest tests for auth.py"

# Documentation
ask "explain this codebase" --context full
```

### System Administration

```bash
# Diagnose issues
docker ps | ask "which containers are unhealthy?"

# Performance analysis
top -bn1 | ask "what's consuming resources?"

# Security audit
ask --agent "find files with 777 permissions"
```

## Contributing

Contributions welcome! ask is designed to be:

- **Simple** - Pure bash, easy to understand
- **Powerful** - Real developer workflows
- **Safe** - Always confirm dangerous operations
- **Extensible** - Easy to add providers/features

## Philosophy

ask follows the Unix philosophy:

1. **Do one thing well** - Shell-native AI assistance
2. **Work together** - Pipe-friendly, composable
3. **Text streams** - Universal interface
4. **Simple** - Bash script, no complex dependencies

Built for developers who never leave the terminal.

## Troubleshooting

### Command not found

```bash
# Check installation
which ask

# Verify it's executable
chmod +x /usr/local/bin/ask

# Check PATH
echo $PATH
```

### API key errors

```bash
# Verify key is set
echo $ANTHROPIC_API_KEY

# Test manually
ask --version
```

### Streaming issues

```bash
# Disable streaming if terminal has issues
ask -n "your query"
```

## License

MIT License - See LICENSE file

## Links

- **GitHub**: <https://github.com/elias-ba/ask>
- **Issues**: <https://github.com/elias-ba/ask/issues>
- **Discussions**: <https://github.com/elias-ba/ask/discussions>
