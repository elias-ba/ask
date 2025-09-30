# ask Example Scripts

Practical, ready-to-use scripts demonstrating real-world ask workflows.

## Available Scripts

### 1. automated-review.sh

Automated code review for git changes using AI analysis.

**Use case**: Review all code changes before creating a PR, during code reviews, or as part of CI/CD pipeline.

**Features**:

- Reviews all changed code files vs base branch
- Security vulnerability scanning
- Bug risk analysis
- Performance issue detection
- Code quality assessment
- Generates executive summary

**Usage**:

```bash
# Review against main branch (default)
./automated-review.sh

# Review against different branch
./automated-review.sh develop

# Review current PR
git checkout feature-branch
./automated-review.sh main
```

**Output Example**:

```bash
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[1] Reviewing: src/auth.js
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ Good:
  - Uses bcrypt for password hashing
  - Implements JWT token validation

⚠ Issues:
  - Missing rate limiting on login endpoint
  - JWT secret should be loaded from environment

💡 Suggestions:
  - Add express-rate-limit middleware
  - Move JWT_SECRET to .env file
```

**CI/CD Integration**:

```yaml
# .github/workflows/review.yml
- name: AI Code Review
  run: |
    ./examples/automated-review.sh main > review.txt
    cat review.txt
```

---

### 2. batch-analyze.sh

Batch analysis of log files with AI-powered insights and summary reporting.

**Use case**: Analyze multiple log files to identify patterns, errors, and system health issues.

**Features**:

- Processes multiple log files in directory
- Counts errors, warnings, and critical issues
- AI analysis of each log file
- Generates executive summary
- Creates detailed report file
- Handles large files efficiently

**Usage**:

```bash
# Analyze all .log files in current directory
./batch-analyze.sh

# Analyze specific directory
./batch-analyze.sh /var/log

# Analyze with custom pattern
./batch-analyze.sh /var/log "*.error.log"

# Analyze application logs
./batch-analyze.sh ./logs "app-*.log"
```

**Output**:

- Creates timestamped report: `analysis-YYYYMMDD-HHMMSS.txt`
- Console output shows progress and summary
- Report includes per-file analysis and executive summary

**Report Structure**:

```bash
Batch Log Analysis Report
Generated: 2025-01-15 10:30:45
Directory: /var/log
Pattern: *.log
================================================================================

File: /var/log/app.log
--------------------------------------------------------------------------------
Size: 2.3M | Lines: 45201
Errors: 127 | Warnings: 45 | Critical: 3

Analysis:
The log shows three critical database connection failures...
[detailed AI analysis]

================================================================================
EXECUTIVE SUMMARY
================================================================================

Files Analyzed: 5
Total Critical: 8
Total Errors: 234
Total Warnings: 156

Overall system health: Moderate concerns
Top 3 priorities:
1. Address database connection pool exhaustion
2. Investigate memory leak in worker process
3. Review authentication failures spike

Recommended actions: [AI recommendations]
```

**Cron Integration**:

```bash
# Daily log analysis at 6 AM
0 6 * * * /path/to/batch-analyze.sh /var/log "app-*.log" && \
  mail -s "Daily Log Analysis" admin@example.com < analysis-*.txt
```

---

### 3. smart-commit.sh

AI-powered git commit with semantic message generation.

**Use case**: Generate professional, semantic commit messages automatically from your staged changes.

**Features**:

- Analyzes git diff to understand changes
- Generates semantic commit messages (conventional commits)
- Interactive confirmation and editing
- Message regeneration with different creativity
- Amend last commit option
- Auto-push to remote
- Validates commit message format

**Usage**:

```bash
# Basic usage
git add src/auth.js
./smart-commit.sh

# Commit and push
git add .
./smart-commit.sh --push

# Amend last commit
./smart-commit.sh --amend

# Amend and force push
./smart-commit.sh --amend --push
```

**Interactive Flow**:

```bash
$ ./smart-commit.sh
Smart Commit

→ Analyzing staged changes...
Files:
 src/auth.js | 23 ++++++++++++++-------
 1 file changed, 16 insertions(+), 7 deletions(-)

→ Generating commit message...

Generated commit message:
feat(auth): add OAuth2 login support

Options:
  y - Use this message
  e - Edit message
  r - Regenerate message
  n - Cancel

Choice (y/e/r/n): y

→ Committing...
✓ Changes committed

Commit details:
a3f21b9 feat(auth): add OAuth2 login support (just now)

✓ Done!
```

**Commit Message Format**:

```bash
<type>(<scope>): <description>

Types:
- feat: New feature
- fix: Bug fix
- docs: Documentation changes
- style: Code style changes
- refactor: Code refactoring
- test: Adding tests
- chore: Maintenance tasks
- perf: Performance improvements

Examples:
- feat(api): add user authentication endpoint
- fix(db): resolve race condition in user creation
- docs(readme): update installation instructions
- refactor(auth): simplify JWT validation logic
```

**Git Aliases**:

```bash
# Add to ~/.gitconfig
[alias]
    sc = !bash /path/to/smart-commit.sh
    scp = !bash /path/to/smart-commit.sh --push
    sca = !bash /path/to/smart-commit.sh --amend
```

Then use: `git sc`, `git scp`, `git sca`

---

## Installation

Make scripts executable:

```bash
chmod +x examples/*.sh
```

Add to PATH for easy access:

```bash
# Add to ~/.bashrc or ~/.zshrc
export PATH="$PATH:/path/to/ask/examples"
```

Or create aliases:

```bash
alias code-review='~/ask/examples/automated-review.sh'
alias analyze-logs='~/ask/examples/batch-analyze.sh'
alias smart-commit='~/ask/examples/smart-commit.sh'
```

## Requirements

All scripts require:

- **bash** 3.x or higher
- **git** (for review and commit scripts)
- **ask** installed and configured with API key

Optional:

- **jq** for JSON processing
- **less** for viewing reports

## Configuration

Scripts use these defaults that you can modify:

```bash
# In automated-review.sh
REVIEW_MODEL="claude-sonnet-4-5-20250929"
REVIEW_PROVIDER="anthropic"

# In batch-analyze.sh
MODEL="claude-sonnet-4-5-20250929"
PROVIDER="anthropic"

# In smart-commit.sh
MODEL="claude-sonnet-4-5-20250929"
PROVIDER="anthropic"
```

To use different models:

```bash
# Edit the script or set environment variables
export ASK_MODEL="gpt-4o"
export ASK_PROVIDER="openai"
```

## Customization

### Create Your Own Scripts

Template for new scripts:

```bash
#!/usr/bin/env bash
set -e

# Your script configuration
MODEL="claude-sonnet-4-5-20250929"
PROVIDER="anthropic"

# Your logic here

# Call ask for analysis
result=$(ask -p "$PROVIDER" -m "$MODEL" --no-stream \
    --system "You are an expert in X" \
    "Your prompt here" < input.txt)

echo "$result"
```

### Common Patterns

**Progress indicators**:

```bash
echo -e "${BLUE}→ Processing...${NC}"
```

**Error handling**:

```bash
if ! command; then
    echo -e "${RED}Error: description${NC}"
    exit 1
fi
```

**File processing loop**:

```bash
for file in *.txt; do
    echo "Processing $file..."
    result=$(ask "analyze" < "$file")
done
```

## Tips

### For Code Review

- Run before creating PRs to catch issues early
- Use in CI/CD to enforce code quality
- Review security-sensitive changes carefully

### For Log Analysis

- Schedule regular analysis with cron
- Set up alerting based on critical issues
- Archive analysis reports for trending

### For Smart Commits

- Stage related changes together
- Review generated message before accepting
- Use --amend to fix typos in last commit
- Combine with pre-commit hooks

## Troubleshooting

**Script fails with "command not found"**:

```bash
# Make sure ask is in PATH
which ask

# Or provide full path in script
ASK_PATH="/usr/local/bin/ask"
$ASK_PATH "your query"
```

**API rate limits**:

```bash
# Add delays between calls
sleep 2
```

**Large file processing**:

```bash
# Sample large files instead of processing entirely
tail -1000 large.log | ask "analyze"
```

## Contributing

Have a useful script? Share it!

1. Create your script in `examples/`
2. Add documentation to this README
3. Submit a PR

Script guidelines:

- Include help text (`--help`)
- Use error handling (`set -e`)
- Add comments explaining logic
- Follow existing script structure
- Test on multiple platforms

## More Examples

For more usage examples and patterns, see:

- [EXAMPLES.md](../docs/EXAMPLES.md) - Comprehensive usage guide
- [QUICKSTART.md](../docs/QUICKSTART.md) - Getting started guide

---

don't grep. don't awk. just ask
