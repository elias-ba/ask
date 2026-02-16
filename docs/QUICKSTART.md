# ask Quick Start Guide

Get up and running with ask in 5 minutes.

## Installation

### One-Line Install

```bash
curl -fsSL https://raw.githubusercontent.com/elias-ba/ask/main/install.sh | bash
```

### Manual Install

```bash
curl -o ask https://raw.githubusercontent.com/elias-ba/ask/main/ask
chmod +x ask
sudo mv ask /usr/local/bin/
```

### Verify Installation

```bash
ask --version
# ask v0.5.0
```

## Setup API Key

ask makes this super easy - no need to edit config files!

### Set Your API Key

```bash
ask keys set anthropic
# You'll be prompted to paste your key (it won't show on screen)
```

That's it! ask stores it securely in `~/.config/ask/keys.env`.

### Get an API Key

Choose a provider:

**Anthropic (Recommended)** - Get key at: <https://console.anthropic.com/>

- Free tier available
- Best for code and reasoning

**OpenAI** - Get key at: <https://platform.openai.com/api-keys>

- GPT-4, GPT-3.5 models
- Pay as you go

**Google Gemini** - Get key at: <https://aistudio.google.com/apikey>

- Free tier available
- Fast and powerful models

**OpenRouter** - Get key at: <https://openrouter.ai/keys>

- Access to many models
- Single API for everything

### Verify Setup

```bash
# Check your configured keys
ask keys list

# Should show:
# ✓ anthropic: sk-ant-...xyz
```

### Alternative: Environment Variables

If you prefer the old way:

```bash
export ANTHROPIC_API_KEY='sk-ant-your-key-here'
```

## First Commands (2 minutes)

### 1. Ask a Simple Question

```bash
ask "how do I find large files in Linux?"
```

You'll see a streaming response instantly!

### 2. Use with Pipes

```bash
ls -lh | ask "explain this output"
```

ask understands piped input naturally.

### 3. Interactive Mode

```bash
ask
```

Start a conversation:

```bash
ask> explain docker containers
Assistant: [Streaming response...]

ask> show me an example
Assistant: [Another response...]

ask> /exit
```

### 4. Generate a Commit Message

```bash
git add .
ask commit
```

ask analyzes your staged changes and suggests a semantic commit message.

## Essential Commands

| Command                  | What it does                |
| ------------------------ | --------------------------- |
| `ask "question"`         | Quick one-off query         |
| `ask`                    | Interactive mode            |
| `ask commit`             | Generate git commit message |
| `ask --help`             | Show all options            |
| `command \| ask "query"` | Use with pipes              |

## Power Features

### Agent Mode

Let ask execute tasks:

```bash
ask --agent "find all TODO comments and count them by file"
```

ask will:

1. Create a safe execution plan
2. Show you what it will do
3. Ask for confirmation
4. Execute each step

### Generate Reusable Functions

```bash
ask --fn parse_logs "extract error lines from log files"
```

ask creates a bash function you can use forever:

```bash
source ~/.config/ask/functions.sh
parse_logs /var/log/app.log
```

### Context Awareness

```bash
# ask automatically includes:
# - Current directory
# - Git status (if in repo)
# - Recent commands
# - System info

ask --context full "why did that command fail?"
```

## Pro Tips

### 1. Use Aliases

Add to your shell config:

```bash
alias a='ask'
alias ac='ask commit'
alias ar='ask pr-review'
```

Now: `a "your question"`

### 2. Pipe Everything

```bash
docker ps | ask "which containers are using most memory?"
cat error.log | ask "group errors by type"
git log --oneline | ask "summarize changes this week"
```

### 3. Switch Models

```bash
# Fast & cheap
ask -m gpt-4o-mini "quick question"

# Google Gemini (fast & free tier)
ask -p google -m gemini-2.5-flash "quick question"

# Powerful reasoning
ask -m claude-opus-4 "complex analysis"
```

### 4. Save Important Conversations

In interactive mode:

```bash
ask> /save  # Save conversation
ask> /load  # Resume later
```

## Common Use Cases

### Development

```bash
# Understand code
cat myfile.py | ask "explain this code"

# Generate tests
ask --fn test_auth "create pytest tests for auth module"

# Review PRs
git diff main..feature | ask "review this code"
```

### System Administration

```bash
# Debug issues
ps aux | ask "what's using all the CPU?"

# Analyze logs
tail -100 /var/log/syslog | ask "any problems?"

# Cleanup tasks
ask --agent "remove old docker images"
```

### Data Analysis

```bash
# CSV analysis
cat data.csv | ask "what are the key insights?"

# JSON parsing
cat api.json | ask "extract all error messages"

# Log patterns
ask "find common error patterns" < app.log
```

## Troubleshooting

### "ask: command not found"

```bash
# Check if in PATH
which ask

# If not, add to PATH
export PATH="$HOME/.local/bin:$PATH"
```

### "API key not set"

```bash
# Check if set
echo $ANTHROPIC_API_KEY

# Set it
export ANTHROPIC_API_KEY='sk-ant-...'

# Make permanent
echo "export ANTHROPIC_API_KEY='sk-ant-...'" >> ~/.bashrc
```

### "curl: command not found"

```bash
# Ubuntu/Debian
sudo apt-get install curl jq

# macOS
brew install curl jq

# Fedora
sudo dnf install curl jq
```

### Streaming Not Working?

```bash
# Disable streaming
ask -n "your question"
```

## Next Steps

1. **Read Examples**: `cat EXAMPLES.md` or visit the GitHub repo
2. **Explore Interactive Mode**: Try `ask` and use `/help`
3. **Generate Your First Function**: `ask --fn` for a task you do often
4. **Try Agent Mode**: `ask --agent --dry-run` to see what it would do
5. **Integrate with Git**: Use `ask commit` in your workflow

## You're Ready

Start simple:

```bash
ask "what can you help me with?"
```

**Remember**: don't grep. don't awk. just ask

---

**Need more help?**

- Full documentation: `ask --help`
- Examples: See `EXAMPLES.md`
- Issues: <https://github.com/elias-ba/ask/issues>
