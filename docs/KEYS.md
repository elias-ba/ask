# ask Key Management

ask provides built-in, secure API key management so you don't need to mess with environment variables.

## Quick Start

### First Time Setup

```bash
# Set your API key (will prompt securely)
ask keys set anthropic

# Paste your key when prompted (won't show on screen)
# Enter your anthropic API key:
# [key is hidden as you type]
```

That's it! Your key is saved and ready to use.

## Commands

### Set a Key

```bash
ask keys set anthropic
ask keys set openai
ask keys set openrouter
```

You'll be prompted to enter the key securely (it won't show on screen).

### List Configured Keys

```bash
ask keys list

# Output:
# Configured API Keys:
# ✓ anthropic: sk-ant-...xyz
# ○ openai: not set
# ○ openrouter: not set
```

Shows masked versions of your keys for security.

### Remove a Key

```bash
ask keys remove anthropic
```

### Show Keys File Location

```bash
ask keys path

# Output: /home/user/.config/ask/keys.env
```

## Security

### Where Keys Are Stored

Keys are stored in: `~/.config/ask/keys.env`

This file has `600` permissions (readable only by you):

```bash
-rw------- 1 user user  123 Jan 01 12:00 keys.env
```

### File Format

The keys file is simple:

```bash
ANTHROPIC_API_KEY=sk-ant-your-key-here
OPENAI_API_KEY=sk-your-key-here
```

### Priority

ask loads keys in this order:

1. **Environment variables** (if already set)
2. **Keys file** (`~/.config/ask/keys.env`)

Environment variables take precedence, so you can override the saved keys temporarily.

## Common Use Cases

### Switch Between Keys Temporarily

```bash
# Override saved key for one command
ANTHROPIC_API_KEY='different-key' ask "test query"

# Or for a session
export ANTHROPIC_API_KEY='different-key'
ask "query 1"
ask "query 2"
```

### Multiple Accounts

```bash
# Save your work key
ask keys set anthropic
# (paste work key)

# Use personal key temporarily
ANTHROPIC_API_KEY='personal-key' ask "personal query"

# Work key is still saved for normal use
ask "work query"
```

### Team Setup

Share this with your team:

```bash
# Each team member runs:
ask keys set anthropic
# Paste team key

# Or set environment variable in shared script:
export ANTHROPIC_API_KEY='team-key'
```

## Environment Variables vs Key Management

### Using ask Key Management (Recommended)

✅ Easier setup - no config file editing  
✅ Secure by default (600 permissions)  
✅ Easy to update (`ask keys set`)  
✅ Easy to see what's configured (`ask keys list`)  
✅ Works out of the box

```bash
ask keys set anthropic
ask "your question"
```

### Using Environment Variables (Traditional)

✅ More control  
✅ Can set in CI/CD easily  
✅ Can scope to terminal session  
⚠️ Need to edit shell config  
⚠️ Easy to forget to source

```bash
export ANTHROPIC_API_KEY='sk-ant-...'
echo 'export ANTHROPIC_API_KEY="sk-ant-..."' >> ~/.bashrc
source ~/.bashrc
ask "your question"
```

## Troubleshooting

### "API key not set" error

```bash
# Check if key is configured
ask keys list

# If not, set it
ask keys set anthropic
```

### Want to use environment variable instead

```bash
# Just set it - it takes precedence
export ANTHROPIC_API_KEY='your-key'
```

### Key not working

```bash
# Check it's correct
ask keys list

# Remove and re-add
ask keys remove anthropic
ask keys set anthropic
```

### Forgot which provider I configured

```bash
ask keys list

# Shows all providers and their status
```

### Want to move keys file

```bash
# Keys file location
ask keys path

# Move it
mv ~/.config/ask/keys.env /new/location/keys.env

# Set XDG_CONFIG_HOME to new location
export XDG_CONFIG_HOME=/new/location
```

## Best Practices

### 1. Use ask Key Management for Personal Use

```bash
ask keys set anthropic
```

Simple, secure, easy.

### 2. Use Environment Variables for CI/CD

```yaml
# GitHub Actions
env:
  ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}

- run: ask "generate report"
```

### 3. Never Commit Keys

```bash
# Add to .gitignore
echo "keys.env" >> .gitignore
```

### 4. Rotate Keys Regularly

```bash
# Every 90 days
ask keys set anthropic
# (paste new key)
```

### 5. Use Different Keys per Environment

```bash
# Production
export ANTHROPIC_API_KEY='prod-key'

# Development (saved)
ask keys set anthropic
# (paste dev key)

# Production deploys use env var
# Local dev uses saved key
```

## Pro Tips

### Quick Key Rotation

```bash
# One command to rotate
ask keys set anthropic && echo "✓ Key rotated"
```

### Backup Keys File

```bash
# Backup
cp ~/.config/ask/keys.env ~/Dropbox/backups/ask-keys.env.backup

# Restore
cp ~/Dropbox/backups/ask-keys.env.backup ~/.config/ask/keys.env
```

### Check Key Before Long Operation

```bash
ask keys list
ask --agent "long operation"
```

### Multi-Provider Setup

```bash
# Set up all providers
ask keys set anthropic
ask keys set openai
ask keys set openrouter

# Switch between them easily
ask -p anthropic "query"
ask -p openai "query"
ask -p openrouter "query"
```

---

## Summary

**Quick Setup:**

```bash
ask keys set anthropic
```

**Check Status:**

```bash
ask keys list
```

**That's it!** ask handles the rest securely.
