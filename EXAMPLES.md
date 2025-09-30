# ASK - Usage Examples

Real-world examples of using ASK in your daily workflow.

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
# Smart commits
git add .
ask commit
# Generates: "feat(api): add user authentication endpoint"

# Review changes
git diff main..feature | ask "review this PR for issues"

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

## Agent Mode

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

## Function Generation

### Log Parsing

```bash
# Nginx logs
ask --fn parse_nginx_errors "extract all 500 errors with timestamp and URL"

# Application logs
ask --fn find_slow_queries "find SQL queries taking more than 1 second"

# System logs
ask --fn tail_errors "tail system logs and highlight errors in red"
```

### Data Processing

```bash
# CSV manipulation
ask --fn csv_unique "get unique values from column in CSV"

# JSON queries
ask --fn json_extract "extract specific field from JSON using jq"

# Text processing
ask --fn extract_emails "find all email addresses in a file"
```

### Git Helpers

```bash
# Branch management
ask --fn git_clean_branches "delete merged local branches"

# Commit helpers
ask --fn git_amend_author "change author of last N commits"

# Statistics
ask --fn git_contributor_stats "show commits per author this month"
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
```

### JSON Processing

```bash
# Query complex JSON
cat api_response.json | ask "extract all user emails where status is active"

# Validate structure
ask "is this valid JSON and what structure does it have?" < data.json

# Transform data
cat input.json | ask "convert this to CSV format"
```

### Log Analysis

```bash
# Error patterns
cat app.log | ask "group errors by type and show frequency"

# Performance metrics
cat access.log | ask "calculate average response time by endpoint"

# Security audit
cat auth.log | ask "find suspicious login attempts"
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
```

### Compliance

```bash
# GDPR check
ask "scan this code for GDPR compliance issues" < user_service.py

# License audit
ask --agent "list all open source licenses in node_modules"

# Secret detection
ask --agent "scan for exposed API keys or credentials"
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
```

### CI/CD Debugging

```bash
# Build failures
ask "why did this build fail?" < build.log

# Deployment issues
ask --context full "debug this deployment failure"

# Performance regression
ask "compare these benchmark results" < benchmarks.txt
```

### Infrastructure

```bash
# Terraform
terraform plan | ask "explain these changes in plain English"

# Ansible
ask "convert this bash script to an Ansible playbook" < deploy.sh

# Configuration
ask "review this nginx config for security issues" < nginx.conf
```

## Pro Tips

### Context Awareness

```bash
# Use context levels strategically
ask --context min "quick question"     # Fast, minimal context
ask --context auto "debug this"        # Balanced (default)
ask --context full "complex analysis"  # Maximum context
```

### Chaining Commands

```bash
# Multi-step pipeline
git diff | ask "summarize changes" | ask "suggest commit message"

# Complex workflows
find . -name "*.js" | xargs cat | ask "find code smells"
```

### Combining with Tools

```bash
# With fzf
ask "list all git commands" | fzf

# With watch
watch -n 60 "docker ps | ask 'are there issues?'"

# With cron
0 */4 * * * ask --agent "cleanup old logs" >> /var/log/ask.log
```

### Model Selection

```bash
# Fast responses
ask -m gpt-4o-mini "quick question"

# Complex reasoning
ask -m claude-opus-4 "design a system architecture"

# Cost-effective
ask -m gpt-3.5-turbo "simple task"
```

### Saving Conversations

```bash
# Important discussions
ask "complex topic"
# ... conversation ...
ask --save  # Save for later

# Resume later
ask --load  # Continue conversation
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
```

### Generate Documentation

```bash
# Code documentation
cat myfunction.py | ask "generate docstring for this function"

# README generation
ask "create a README for this project" --context full

# API documentation
ask "document this REST API" < api_routes.js
```

### Quick References

```bash
# Command syntax
ask "show me grep examples for common use cases"

# Best practices
ask "what are bash scripting best practices?"

# Cheat sheets
ask "give me a jq cheat sheet"
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
```

### Code Review Workflow

```bash
# 1. Get PR details
git diff main..feature > /tmp/pr.diff

# 2. Review
ask "code review this PR" < /tmp/pr.diff

# 3. Test suggestions
ask "suggest test cases for this PR" < /tmp/pr.diff

# 4. Documentation check
ask "does this PR need documentation updates?" < /tmp/pr.diff
```

### Debugging Workflow

```bash
# 1. Capture error
./myapp 2>&1 | tee error.log

# 2. Initial analysis
ask "what's wrong?" < error.log

# 3. Deep dive
ask --context full "debug this error"

# 4. Generate fix
ask --agent "fix this issue" --dry-run
```

---

**More examples?** Share yours! Open a PR or discussion on GitHub.

**Need help?** Just ASK! 😉

```bash
ask "how do I use ASK effectively?"
```
