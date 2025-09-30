#!/usr/bin/env bash

# automated-review.sh
# Automated code review for git changes
# Usage: ./automated-review.sh [base-branch]

set -e

BASE_BRANCH="${1:-main}"
REVIEW_MODEL="claude-sonnet-4-5-20250929"
REVIEW_PROVIDER="anthropic"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${CYAN}${BOLD}Automated Code Review${NC}"
echo -e "${CYAN}Base branch: ${BASE_BRANCH}${NC}\n"

if ! git rev-parse --git-dir &>/dev/null; then
    echo -e "${RED}Error: Not in a git repository${NC}"
    exit 1
fi

if ! git rev-parse --verify "$BASE_BRANCH" &>/dev/null; then
    echo -e "${RED}Error: Branch '$BASE_BRANCH' does not exist${NC}"
    exit 1
fi

echo -e "${BLUE}→ Getting changed files...${NC}"
changed_files=$(git diff --name-only "$BASE_BRANCH" | grep -E '\.(js|py|sh|ts|jsx|tsx|go|rs|java|c|cpp|h)$' || true)

if [ -z "$changed_files" ]; then
    echo -e "${YELLOW}No code files changed${NC}"
    exit 0
fi

echo -e "${GREEN}Found $(echo "$changed_files" | wc -l) changed code files${NC}\n"

review_count=0
for file in $changed_files; do
    if [ ! -f "$file" ]; then
        echo -e "${YELLOW}⊘ Skipping deleted file: $file${NC}"
        continue
    fi
    
    review_count=$((review_count + 1))
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}[$review_count] Reviewing: $file${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    diff=$(git diff "$BASE_BRANCH" -- "$file")
    
    echo "$diff" | ask -p "$REVIEW_PROVIDER" -m "$REVIEW_MODEL" --no-stream \
        --system "You are an expert code reviewer. Focus on:
1. Security vulnerabilities
2. Bug risks and edge cases
3. Performance issues
4. Code quality and maintainability
5. Best practices violations

Be concise but thorough. Format as:
- ✓ Good: [positive points]
- ⚠ Issues: [problems found]
- 💡 Suggestions: [improvements]" \
        "Review these code changes"
    
    echo -e "\n"
done

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}Summary${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

full_diff=$(git diff "$BASE_BRANCH")

echo "$full_diff" | ask -p "$REVIEW_PROVIDER" -m "$REVIEW_MODEL" --no-stream \
    --system "You are a senior engineering lead. Provide a high-level summary of the changes." \
    "Summarize this code review in 3-4 sentences. Include:
1. Overall quality assessment
2. Main concerns (if any)
3. Recommendation (approve, request changes, or needs discussion)"

echo -e "\n${GREEN}✓ Review complete!${NC}"
echo -e "${BLUE}Files reviewed: $review_count${NC}"
