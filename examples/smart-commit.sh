#!/usr/bin/env bash

# smart-commit.sh
# git commit with AI-generated messages
# Usage: ./smart-commit.sh [--push] [--amend]

set -e

MODEL="claude-sonnet-4-5-20250929"
PROVIDER="anthropic"
PUSH_AFTER=false
AMEND_LAST=false

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

while [[ $# -gt 0 ]]; do
    case $1 in
        --push)
            PUSH_AFTER=true
            shift
            ;;
        --amend)
            AMEND_LAST=true
            shift
            ;;
        -h|--help)
            cat <<EOF
${CYAN}${BOLD}smart-commit.sh${NC}
AI-powered git commit message generator

${YELLOW}Usage:${NC}
  ./smart-commit.sh [OPTIONS]

${YELLOW}Options:${NC}
  --push      Push to remote after commit
  --amend     Amend the last commit instead
  -h, --help  Show this help

${YELLOW}Examples:${NC}
  ./smart-commit.sh
  ./smart-commit.sh --push
  ./smart-commit.sh --amend

${YELLOW}How it works:${NC}
  1. Analyzes staged changes (or last commit if --amend)
  2. Generates semantic commit message
  3. Shows preview and asks for confirmation
  4. Commits with generated message
  5. Optionally pushes to remote

${CYAN}Requires: git, ask${NC}
EOF
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

echo -e "${CYAN}${BOLD}Smart Commit${NC}\n"

if ! git rev-parse --git-dir &>/dev/null; then
    echo -e "${RED}Error: Not in a git repository${NC}"
    exit 1
fi

if [ "$AMEND_LAST" = true ]; then
    echo -e "${BLUE}→ Analyzing last commit for amendment...${NC}"
    
    if ! git rev-parse HEAD &>/dev/null; then
        echo -e "${RED}Error: No commits to amend${NC}"
        exit 1
    fi
    
    diff=$(git show HEAD)
    old_message=$(git log -1 --pretty=%B)
    
    echo -e "${CYAN}Current commit message:${NC}"
    echo -e "${YELLOW}$old_message${NC}\n"
else
    echo -e "${BLUE}→ Analyzing staged changes...${NC}"
    
    if ! git diff --cached --quiet; then
        diff=$(git diff --cached)
    else
        echo -e "${YELLOW}No staged changes found${NC}"
        echo -e "${CYAN}Stage changes with: ${BOLD}git add <files>${NC}"
        exit 1
    fi
fi

echo -e "${CYAN}Files:${NC}"
if [ "$AMEND_LAST" = true ]; then
    git show --stat HEAD | tail -n +2
else
    git diff --cached --stat
fi
echo

echo -e "${BLUE}→ Generating commit message...${NC}\n"

commit_message=$(echo "$diff" | ask -p "$PROVIDER" -m "$MODEL" --no-stream \
    --system "You are a git commit message expert. Generate concise, semantic commit messages following conventional commits format.

Format: <type>(<scope>): <description>

Types: feat, fix, docs, style, refactor, test, chore, perf
Scope: optional, component/area affected
Description: imperative mood, lowercase, no period

Examples:
- feat(auth): add OAuth2 login support
- fix(api): resolve race condition in user creation
- docs(readme): update installation instructions
- refactor(db): simplify query builder logic

Rules:
1. Keep description under 50 characters
2. Be specific but concise
3. Use imperative mood (add, fix, update, not added, fixed, updated)
4. Return ONLY the commit message, no explanation" \
    "Generate a semantic commit message for these changes" 2>/dev/null)

commit_message=$(echo "$commit_message" | sed 's/^["`]*//' | sed 's/["`]*$//' | sed 's/^commit message: //i' | head -1)

if [ -z "$commit_message" ]; then
    echo -e "${RED}Error: Failed to generate commit message${NC}"
    exit 1
fi

echo -e "${GREEN}${BOLD}Generated commit message:${NC}"
echo -e "${CYAN}$commit_message${NC}\n"

echo -e "${YELLOW}Options:${NC}"
echo -e "  ${GREEN}y${NC} - Use this message"
echo -e "  ${GREEN}e${NC} - Edit message"
echo -e "  ${GREEN}r${NC} - Regenerate message"
echo -e "  ${GREEN}n${NC} - Cancel"
echo -e "\n${YELLOW}Choice (y/e/r/n):${NC} "
read -r choice

case $choice in
    y|Y)
        final_message="$commit_message"
        ;;
    e|E)
        tmp_file=$(mktemp)
        echo "$commit_message" > "$tmp_file"
        ${EDITOR:-vi} "$tmp_file"
        final_message=$(cat "$tmp_file")
        rm "$tmp_file"
        
        if [ -z "$final_message" ]; then
            echo -e "${RED}Error: Empty commit message${NC}"
            exit 1
        fi
        ;;
    r|R)
        echo -e "\n${BLUE}→ Regenerating with more creativity...${NC}\n"
        
        commit_message=$(echo "$diff" | ask -p "$PROVIDER" -m "$MODEL" --no-stream -t 1.2 \
            --system "You are a git commit message expert. Generate concise, semantic commit messages following conventional commits format.

Format: <type>(<scope>): <description>

Types: feat, fix, docs, style, refactor, test, chore, perf
Scope: optional, component/area affected
Description: imperative mood, lowercase, no period

Be creative but accurate. Focus on the 'why' if it's clear from the diff.
Return ONLY the commit message, no explanation" \
            "Generate a semantic commit message for these changes" 2>/dev/null)
        
        commit_message=$(echo "$commit_message" | sed 's/^["`]*//' | sed 's/["`]*$//' | head -1)
        
        echo -e "${GREEN}${BOLD}New message:${NC}"
        echo -e "${CYAN}$commit_message${NC}\n"
        
        echo -e "${YELLOW}Use this message? (y/n):${NC} "
        read -r confirm
        
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            final_message="$commit_message"
        else
            echo -e "${YELLOW}Commit cancelled${NC}"
            exit 0
        fi
        ;;
    n|N|*)
        echo -e "${YELLOW}Commit cancelled${NC}"
        exit 0
        ;;
esac

echo -e "\n${BLUE}→ Committing...${NC}"

if [ "$AMEND_LAST" = true ]; then
    git commit --amend -m "$final_message"
    echo -e "${GREEN}✓ Commit amended${NC}"
else
    git commit -m "$final_message"
    echo -e "${GREEN}✓ Changes committed${NC}"
fi

echo -e "\n${CYAN}Commit details:${NC}"
git log -1 --pretty=format:"%C(yellow)%h%Creset %s %C(cyan)(%cr)%Creset"
echo -e "\n"

if [ "$PUSH_AFTER" = true ]; then
    current_branch=$(git branch --show-current)
    
    echo -e "${BLUE}→ Pushing to remote...${NC}"
    
    if git rev-parse --abbrev-ref --symbolic-full-name @{u} &>/dev/null; then
        if [ "$AMEND_LAST" = true ]; then
            echo -e "${YELLOW}Force pushing amended commit...${NC}"
            git push --force-with-lease
        else
            git push
        fi
        echo -e "${GREEN}✓ Pushed to remote${NC}"
    else
        echo -e "${YELLOW}No upstream branch set${NC}"
        echo -e "${CYAN}Set upstream to origin/$current_branch? (y/n):${NC} "
        read -r set_upstream
        
        if [[ "$set_upstream" =~ ^[Yy]$ ]]; then
            git push -u origin "$current_branch"
            echo -e "${GREEN}✓ Pushed and set upstream${NC}"
        else
            echo -e "${YELLOW}Push skipped${NC}"
        fi
    fi
fi

echo -e "\n${GREEN}${BOLD}✓ Done!${NC}"
