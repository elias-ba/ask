# ask - Usage Examples

Real-world examples of using ask in your daily workflow.

## Quick Queries

### Basic Questions

```bash
# Simple questions
ask "what's the difference between TCP and UDP?"

# Code explanations
ask "explain what this regex does: ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"

# Best practices
ask "what's the best way to handle errors in bash scripts?"
```

### With Piped Input

```bash
# Analyze logs
tail -100 /var/log/nginx/access.log | ask "summarize the traffic patterns"

# Debug errors
cat error.log | ask "what's causing these errors and how to fix?"

# Process data
ps aux | ask "what processes are using the most memory?"
```

### With Custom System Prompts

```bash
# Security expert persona
ask --system "You are a security expert" "review this code for vulnerabilities" < auth.py

# Database performance expert
ask --system "You are a database performance expert" "optimize this SQL query"

# Technical writer
ask --system "You are a technical documentation writer" "document this API" < routes.js
```

### Temperature Control

```bash
# Creative writing (higher temperature = more creative)
ask -t 1.5 "write a creative story about a developer"

# Deterministic output (lower temperature = more focused)
ask -t 0.1 "extract structured data from this JSON" < data.json

# Balanced (default is 1.0)
ask -t 1.0 "explain how async/await works"
```

### JSON Output

```bash
# For programmatic use
ask --json --no-stream "list top 3 security practices" | jq -r '.content[0].text'

# Batch processing
for file in *.log; do
  errors=$(ask --json --no-stream "count error lines" < "$file" | jq -r '.count')
  echo "$file: $errors errors"
done

# Parsing structured responses
result=$(ask --json --no-stream "analyze sentiment" < review.txt)
echo "$result" | jq '.sentiment'
```

### Multi-line Input

```bash
# Complex queries across multiple lines
ask --multiline
# Type your multi-line prompt here
# You can paste code, logs, or long questions
# Press Ctrl+D when done to send

# Example use:
ask --multiline <<'EOF'
Given this error stack trace, explain:
1. Root cause
2. How to fix
3. How to prevent

[paste stack trace here]
EOF
```

## Shell & System Administration

### File Operations

```bash
# Find files intelligently
ask "find all javascript files modified in the last week"

# Analyze disk usage
du -sh * | ask "which directories should I clean up first?"

# Permission issues
ask "why can't I write to this directory?" --context full
```

### Process Management

```bash
# Debug hanging processes
ps aux | grep myapp | ask "is this process stuck?"

# Resource monitoring
top -bn1 | ask "diagnose performance issues"

# Kill processes safely
ask --agent "kill all zombie processes"
```

### Networking

```bash
# Test connectivity
ping -c 5 google.com | ask "analyze the connection quality"

# Port debugging
netstat -tulpn | ask "which service is using port 8080?"

# SSL certificates
openssl s_client -connect example.com:443 | ask "when does this cert expire?"
```

## Development Workflows

### Git Workflows

```bash
# Smart commits (requires staged changes)
git add .
ask commit
# Analyzes git diff --cached and generates:
# "feat(api): add user authentication endpoint"

# Review changes
git diff main..feature | ask "review this PR for issues"

# PR review command
git checkout feature-branch
ask pr-review
# Reviews current branch against main

# Find commits
git log --oneline | ask "find the commit that added authentication"

# Rebase help
ask "explain git rebase -i in simple terms"
```

### Code Review

```bash
# Review specific file
git diff main src/auth.js | ask "security review this authentication code"

# Find bugs
cat bug_report.txt | ask "what's the root cause?" --context full

# Performance analysis
ask "why is this function slow?" < mycode.py

# With security expert
ask --system "You are a security auditor" "find vulnerabilities" < app.py
```

### Testing

```bash
# Generate tests
ask --fn test_user_login "create pytest tests for user login function"

# Debug test failures
pytest -v | ask "why are these tests failing?"

# Coverage analysis
coverage report | ask "what critical paths are missing tests?"
```

### Debugging

```bash
# Diagnose last command failure
make build
# [build fails]
ask diagnose
# Analyzes the last command and its output

# With full context
npm test
# [tests fail]
ask --context full diagnose
```

## Agent Mode

### Basic Agent Usage

```bash
# Simple task
ask --agent "create a backup directory with today's date"

# Agent will:
# 1. Show execution plan
# 2. Display risk levels
# 3. Ask for approval

# Auto-approve low/medium risk (recommended)
ask --agent "organize files by type"
# Type 'a' when prompted to auto-approve safe commands

# Dry run (show plan without executing)
ask --agent --dry-run "delete old log files"
# Reviews the plan without running anything
```

### File Management

```bash
# Organize files
ask --agent "organize these files by file type into subdirectories"

# Cleanup
ask --agent "find and remove files larger than 100MB not modified in 30 days"

# Backup
ask --agent "create timestamped backup of all .conf files"

# Dry run first
ask --agent --dry-run "rename all JPEG files to lowercase"
```

### Docker Operations

```bash
# Cleanup
ask --agent "remove all stopped containers and unused images"

# Health check
ask --agent "restart unhealthy containers"

# Resource management
ask --agent "find containers using more than 1GB RAM"

# Restricted tools (only allow docker commands)
ask --agent --tools "docker" "cleanup unused volumes"
```

### Database Tasks

```bash
# Backup
ask --agent "create postgres dump with timestamp"

# Cleanup
ask --agent "delete logs older than 7 days from analytics table"

# Migration check
ask --agent --dry-run "run pending database migrations"
```

### Agent Error Handling

```bash
# When a command fails, agent asks to continue
ask --agent "deploy application"
# If step 3 fails, you'll be prompted:
# "Continue with next step? (y/n)"

# Agent shows exit codes
# ✓ Success (exit code 0)
# ✗ Failed (exit code 1)
```

### Restricted Agent Tools

```bash
# Only allow specific tools
ask --agent --tools "curl,jq" "fetch and parse this API endpoint"

# Git-only operations
ask --agent --tools "git" "create feature branch and initial commit"

# Safe read-only tools
ask --agent --tools "cat,grep,find" "analyze log patterns"
```

## Function Generation

### Basic Function Generation

```bash
# Generate a function
ask --fn parse_nginx "extract 500 errors from nginx access logs"

# ask will:
# 1. Generate the function
# 2. Validate syntax
# 3. Show preview
# 4. Ask: Save? (y/n/e to edit)

# Functions are saved to ~/.config/ask/functions.sh
```

### Log Parsing

```bash
# Nginx logs
ask --fn parse_nginx_errors "extract all 500 errors with timestamp and URL"

# Application logs
ask --fn find_slow_queries "find SQL queries taking more than 1 second"

# System logs
ask --fn tail_errors "tail system logs and highlight errors in red"

# JSON logs
ask --fn parse_json_logs "parse and pretty-print JSON log entries"
```

### Data Processing

```bash
# CSV manipulation
ask --fn csv_unique "get unique values from column in CSV"

# JSON queries
ask --fn json_extract "extract specific field from JSON using jq"

# Text processing
ask --fn extract_emails "find all email addresses in a file"

# Data transformation
ask --fn csv_to_json "convert CSV file to JSON format"
```

### Git Helpers

```bash
# Branch management
ask --fn git_clean_branches "delete merged local branches"

# Commit helpers
ask --fn git_amend_author "change author of last N commits"

# Statistics
ask --fn git_contributor_stats "show commits per author this month"

# PR helpers
ask --fn git_pr_summary "generate PR summary from branch commits"
```

### Using Generated Functions

```bash
# Source the functions file
source ~/.config/ask/functions.sh

# Now use your functions
parse_nginx_errors /var/log/nginx/access.log
csv_unique data.csv email
git_clean_branches

# Add to .bashrc for permanent use
echo 'source ~/.config/ask/functions.sh' >> ~/.bashrc
```

### Editing Functions

```bash
# Generate with edit option
ask --fn backup_db "create timestamped database backup"
# When prompted, choose 'e' to edit before saving
# Opens in $EDITOR (vim/nano/etc)

# Edit existing functions
vim ~/.config/ask/functions.sh
```

## Interactive Mode

### Starting Interactive Mode

```bash
# Start interactive session
ask

# You'll see:
#            _
#   __ _ ___| | __
#  / _` / __| |/ /
# | (_| \__ \   <
#  \__,_|___/_|\_\
#
# ask v1.0.0
# "don't grep. don't awk. just ask"
#
# Provider: anthropic | Model: claude-sonnet-4-5
# Streaming: true | Context: auto
#
# Type your message (or /help for commands)

ask> your question here
```

### Interactive Session Example

```bash
ask

ask> explain docker containers
[Streaming response about Docker...]

ask> show me an example dockerfile
[Example Dockerfile...]

ask> how do I optimize this for production?
[Optimization tips...]

ask> /save
✓ Conversation saved

ask> /exit
Goodbye!
```

### Interactive Commands

```bash
ask

# Clear conversation history
ask> /clear
✓ Conversation cleared

# Save conversation
ask> /save
✓ Conversation saved

# Load previous conversation
ask> /load
✓ Loaded 12 messages

# List available models
ask> /models
Available models for anthropic:
  → claude-sonnet-4-5-20250929
  → claude-opus-4-1-20250514

# Switch provider/model
ask> /switch openai gpt-4o
✓ Switched to openai/gpt-4o

ask> /switch anthropic
✓ Switched to anthropic/claude-sonnet-4-5-20250929

# Change context level
ask> /context none
✓ Context level: none
# (Faster responses, no system context)

ask> /context full
✓ Context level: full
# (Maximum context for debugging)

# Show help
ask> /help

# Exit
ask> /exit
# or
ask> /quit
```

### Context Levels in Interactive Mode

```bash
ask

# Start with no context (fastest)
ask> /context none
ask> quick calculation question

# Switch to auto for git-aware queries
ask> /context auto
ask> what branch am I on?

# Full context for debugging
ask> /context full
ask> why did my last command fail?
```

## Data Analysis

### CSV Files

```bash
# Analyze data
cat sales.csv | ask "what are the top 5 products by revenue?"

# Find anomalies
cat metrics.csv | ask "detect any unusual patterns in this data"

# Generate reports
cat data.csv | ask "create a summary report with key insights"

# With JSON output for scripting
ask --json --no-stream "analyze sales trends" < sales.csv | jq -r '.insights'
```

### JSON Processing

```bash
# Query complex JSON
cat api_response.json | ask "extract all user emails where status is active"

# Validate structure
ask "is this valid JSON and what structure does it have?" < data.json

# Transform data
cat input.json | ask "convert this to CSV format"

# Nested queries
cat complex.json | ask "find all objects where nested.field.value > 100"
```

### Log Analysis

```bash
# Error patterns
cat app.log | ask "group errors by type and show frequency"

# Performance metrics
cat access.log | ask "calculate average response time by endpoint"

# Security audit
cat auth.log | ask "find suspicious login attempts"

# Multi-file analysis
cat *.log | ask "find correlation between errors across services"
```

## Security & Compliance

### Security Checks

```bash
# File permissions
ask --agent "find files with world-writable permissions"

# Password audit
ask "check if these passwords meet security requirements" < passwords.txt

# Vulnerability scan
npm audit | ask "prioritize these vulnerabilities by severity"

# Code security review
ask --system "You are a security expert" "audit this code" < app.py
```

### Compliance

```bash
# GDPR check
ask "scan this code for GDPR compliance issues" < user_service.py

# License audit
ask --agent "list all open source licenses in node_modules"

# Secret detection
ask --agent "scan for exposed API keys or credentials"

# Security best practices
ask --system "You are a security auditor" "review authentication flow" < auth.js
```

## DevOps & CI/CD

### Kubernetes

```bash
# Debug pods
kubectl get pods | ask "which pods are crashlooping?"

# Resource analysis
kubectl top nodes | ask "which node is overutilized?"

# Log analysis
kubectl logs -f mypod | ask "alert me to errors in real-time"

# Configuration review
kubectl get deployment myapp -o yaml | ask "check for security issues"
```

### CI/CD Debugging

```bash
# Build failures
ask "why did this build fail?" < build.log

# Deployment issues
ask --context full "debug this deployment failure"

# Performance regression
ask "compare these benchmark results" < benchmarks.txt

# With JSON for automation
ask --json --no-stream "extract failure reason" < ci.log | jq -r '.reason'
```

### Infrastructure

```bash
# Terraform
terraform plan | ask "explain these changes in plain English"

# Ansible
ask "convert this bash script to an Ansible playbook" < deploy.sh

# Configuration
ask "review this nginx config for security issues" < nginx.conf

# IaC review
ask --system "You are a DevOps expert" "review this terraform" < main.tf
```

## Advanced Usage

### Combining Multiple Features

```bash
# Expert persona + full context + agent mode
ask --system "You are a DevOps expert" \
    --context full \
    --agent \
    "set up monitoring for this service"

# Custom temperature + system prompt
ask --system "You are a creative writer" \
    -t 1.5 \
    "write a tech blog post about containers"

# JSON output + no streaming for scripting
ask --json --no-stream \
    --system "You are a data analyst" \
    "summarize key metrics" < metrics.csv | jq
```

### Configuration & Environment

```bash
# Set default provider
export ASK_PROVIDER=openai
ask "your question"  # Uses OpenAI

# Set default model
export ASK_MODEL=gpt-4o
ask "your question"  # Uses GPT-4o

# Per-project settings
cd myproject
export ASK_MODEL=claude-opus-4  # More powerful for complex project
ask --context full "review architecture"

# Temporary override
ASK_MODEL=gpt-4o-mini ask "quick question"  # Fast/cheap for this query
```

### Scripting with ask

```bash
#!/bin/bash
# automated-review.sh

# Review all changed files
changed_files=$(git diff --name-only main)

for file in $changed_files; do
  echo "=== Reviewing $file ==="

  # Get review
  git diff main "$file" | ask --no-stream \
    --system "You are a code reviewer" \
    "quick security and quality review"

  echo ""
done

# Generate summary
echo "=== Summary ==="
ask --no-stream "summarize the review findings above"
```

```bash
#!/bin/bash
# batch-analyze.sh

# Analyze multiple log files
for log in /var/log/app/*.log; do
  echo "Analyzing $log..."

  error_count=$(ask --json --no-stream \
    "count error lines" < "$log" | jq -r '.count')

  echo "$log: $error_count errors"

  # If errors found, get details
  if [ "$error_count" -gt 0 ]; then
    ask --no-stream "list unique error types" < "$log" >> errors.txt
  fi
done
```

```bash
#!/bin/bash
# smart-commit.sh

# Stage changes
git add -A

# Generate commit message
msg=$(ask commit --no-stream | head -1)

# Review before committing
echo "Suggested commit: $msg"
read -p "Use this message? (y/n) " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
  git commit -m "$msg"
  echo "✓ Committed"
else
  echo "Cancelled"
fi
```

## Pro Tips

### Context Awareness

```bash
# Use context levels strategically
ask --context min "quick question"     # Fast, minimal context
ask --context auto "debug this"        # Balanced (default)
ask --context full "complex analysis"  # Maximum context

# None for pure queries (no system info)
ask --context none "what is a monad?"
```

### Chaining Commands

```bash
# Multi-step pipeline
git diff | ask "summarize changes" | ask "suggest commit message"

# Complex workflows
find . -name "*.js" | xargs cat | ask "find code smells"

# With intermediate processing
docker ps | ask "identify issues" | grep -i "memory"
```

### Combining with Tools

```bash
# With fzf for selection
ask "list all git commands" | fzf

# With watch for monitoring
watch -n 60 "docker ps | ask 'are there issues?'"

# With cron for automation
0 */4 * * * ask --agent "cleanup old logs" >> /var/log/ask.log

# With xargs for batch operations
find . -name "*.log" -type f | xargs -I {} sh -c 'ask "analyze" < {}'
```

### Model Selection

```bash
# Fast responses (cheap, quick)
ask -m gpt-4o-mini "quick question"

# Complex reasoning (powerful, expensive)
ask -m claude-opus-4 "design a system architecture"

# Balanced (default)
ask -m claude-sonnet-4-5 "explain this code"

# List available models
ask --list-models
ask -p openai --list-models
```

### Saving Conversations

```bash
# Important discussions
ask "complex topic"
# ... multi-turn conversation ...
ask> /save  # In interactive mode
# or
ask --save  # After query

# Resume later
ask --load
# Continues where you left off

# Clear when done
ask --clear
```

### Streaming Control

```bash
# Enable streaming (default, real-time)
ask -s "long explanation"

# Disable for scripting (wait for complete response)
ask -n "generate JSON" | jq

# Disable for parsing
result=$(ask --no-stream "analyze this")
echo "$result" | grep "recommendation"
```

## Learning & Documentation

### Explain Commands

```bash
# Understand complex commands
ask "explain: find . -type f -name '*.log' -mtime +30 -delete"

# Shell scripting help
ask "how does parameter expansion work in bash?"

# Git workflows
ask "explain git rebase vs merge with examples"

# Man page alternative
ask "explain grep options with examples"
```

### Generate Documentation

```bash
# Code documentation
cat myfunction.py | ask "generate docstring for this function"

# README generation
ask "create a README for this project" --context full

# API documentation
ask "document this REST API" < api_routes.js

# Architecture docs
ask --system "You are a technical writer" \
    --context full \
    "document the system architecture"
```

### Quick References

```bash
# Command syntax
ask "show me grep examples for common use cases"

# Best practices
ask "what are bash scripting best practices?"

# Cheat sheets
ask "give me a jq cheat sheet"

# Language reference
ask "python list comprehension examples"
```

## Daily Workflows

### Morning Routine

```bash
# Check system health
ask --context full "daily system health check"

# Review git status
git status | ask "summarize what I was working on"

# Plan work
ask "based on my recent commits, what should I focus on today?"

# Check for issues
docker ps | ask "any containers with issues?"
```

### Code Review Workflow

```bash
# 1. Get PR details
git diff main..feature > /tmp/pr.diff

# 2. Initial review
ask --system "You are a senior code reviewer" \
    "review this PR" < /tmp/pr.diff

# 3. Security check
ask --system "You are a security expert" \
    "security review" < /tmp/pr.diff

# 4. Test suggestions
ask "suggest test cases for this PR" < /tmp/pr.diff

# 5. Documentation check
ask "does this PR need documentation updates?" < /tmp/pr.diff
```

### Debugging Workflow

```bash
# 1. Capture error
./myapp 2>&1 | tee error.log

# 2. Initial analysis
ask "what's wrong?" < error.log

# 3. Deep dive with full context
ask --context full "debug this error"

# 4. Generate fix (dry run first)
ask --agent --dry-run "fix this issue"

# 5. Apply fix
ask --agent "fix this issue"
```

### Deployment Workflow

```bash
# 1. Pre-deployment checks
ask --context full "check if safe to deploy"

# 2. Review changes
git diff production | ask "review deployment changes"

# 3. Generate deployment plan
ask --agent --dry-run "deploy to production"

# 4. Execute deployment
ask --agent "deploy to production"

# 5. Post-deployment validation
ask --context full "validate deployment success"
```

## Key Management

### First Time Setup

```bash
# Set your primary API key
ask keys set anthropic
# (paste key when prompted)

# Add other providers
ask keys set openai
ask keys set openrouter

# Verify setup
ask keys list
```

### Managing Multiple Keys

```bash
# List all configured keys
ask keys list

# Remove a key
ask keys remove openai

# Show where keys are stored
ask keys path
# Output: ~/.config/ask/keys.env

# Temporary override
ANTHROPIC_API_KEY='different-key' ask "test query"
```

## Troubleshooting

### Command Not Found

```bash
# Check installation
which ask

# Check PATH
echo $PATH

# Add to PATH if needed
export PATH="$HOME/.local/bin:$PATH"
```

### API Key Issues

```bash
# Check if key is set
ask keys list

# Re-set key
ask keys set anthropic

# Test with simple query
ask "test"
```

### Streaming Issues

```bash
# Disable streaming if terminal has issues
ask -n "your query"

# Or set as default
export ASK_STREAM=false
```

### Performance Issues

```bash
# Use minimal context for speed
ask --context min "quick question"

# Use smaller/faster model
ask -m gpt-4o-mini "simple task"

# Disable streaming
ask -n "query"
```

---

## More Examples?

**Share yours!** Open a PR or discussion on GitHub.

**Need help?** Just ask:

```bash
ask "how do I use ask effectively?"
```

**Repository**: https://github.com/elias-ba/ask

**don't grep. don't awk. just ask**
