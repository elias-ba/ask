#!/usr/bin/env bash

# ask - AI-powered shell assistant
# don't grep. don't awk. just ask

VERSION="1.0.0"
AUTHOR="Elias W. BA <eliaswalyba@gmail.com>"

if [ -z "$BASH_VERSION" ]; then
    echo "Error: This script requires Bash"
    exit 1
fi

BASH_MAJOR_VERSION="${BASH_VERSION%%.*}"
if [ "$BASH_MAJOR_VERSION" -lt 3 ]; then
    echo "Error: This script requires Bash 3.x or higher"
    echo "Current version: $BASH_VERSION"
    exit 1
fi

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/ask"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/ask"
HISTORY_FILE="$CACHE_DIR/history.jsonl"
FUNCTIONS_FILE="$CONFIG_DIR/functions.sh"
CONTEXT_FILE="$CACHE_DIR/context.json"
KEYS_FILE="$CONFIG_DIR/keys.env"

DEFAULT_PROVIDER="anthropic"
DEFAULT_MODEL="claude-sonnet-4-5-20250929"
DEFAULT_TEMPERATURE="1.0"
DEFAULT_MAX_TOKENS="4096"
STREAM_ENABLED=true
MAX_HISTORY=100

get_models() {
    local provider=$1
    case $provider in
        anthropic) echo "claude-sonnet-4-5-20250929,claude-opus-4-1-20250514,claude-4-opus-20250514" ;;
        openai) echo "gpt-4o,gpt-4o-mini,gpt-4-turbo,o1,o1-mini" ;;
        openrouter) echo "anthropic/claude-sonnet-4-5,openai/gpt-4o,google/gemini-2.0-flash-exp" ;;
        google) echo "gemini-3-pro-preview,gemini-2.5-pro,gemini-2.5-flash,gemini-2.5-flash-lite" ;;
        deepseek) echo "deepseek-chat,deepseek-coder,deepseek-reasoner" ;;
    esac
}

get_api_url() {
    local provider=$1
    case $provider in
        anthropic) echo "https://api.anthropic.com/v1/messages" ;;
        openai) echo "https://api.openai.com/v1/chat/completions" ;;
        openrouter) echo "https://openrouter.ai/api/v1/chat/completions" ;;
        google) echo "https://generativelanguage.googleapis.com/v1beta/models" ;;
        deepseek) echo "https://api.deepseek.com/v1/chat/completions" ;;
    esac
}

get_default_model() {
    local provider=$1
    case $provider in
        anthropic) echo "claude-sonnet-4-5-20250929" ;;
        openai) echo "gpt-4o" ;;
        openrouter) echo "anthropic/claude-sonnet-4-5" ;;
        google) echo "gemini-2.5-flash" ;;
        deepseek) echo "deepseek-chat" ;;
    esac
}

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

CONVERSATION_JSON=""

RENDER_MODE="$DEFAULT_RENDER"

show_thinking() {
    if [ -t 1 ]; then
        THINKING_START_TIME=$(date +%s)
        echo -ne "${CYAN}Thinking...${NC}"
    fi
}

clear_thinking() {
    if [ -t 1 ] && [ "$THINKING_START_TIME" -gt 0 ]; then
        local current_time=$(date +%s)
        local elapsed=$((current_time - THINKING_START_TIME))
        if [ "$elapsed" -lt 1 ]; then
            sleep 0.3
        fi
        printf "\r\033[K"
        THINKING_START_TIME=0
    fi
}

show_banner() {
    cat <<'EOF'
            _
   __ _ ___| | __
  / _` / __| |/ /
 | (_| \__ \   <
  \__,_|___/_|\_\

ask v1.0.0
don't grep. don't awk. just ask

EOF
}

show_help() {
    cat <<EOF
$(echo -e "${CYAN}${BOLD}ask${NC}") - v${VERSION}
don't grep. don't awk. just ask

$(echo -e "${YELLOW}USAGE:${NC}")
    ask [OPTIONS] [PROMPT]
    ask [OPTIONS]              # Interactive mode

$(echo -e "${YELLOW}OPTIONS:${NC}")
    $(echo -e "${GREEN}-p, --provider${NC}") PROVIDER   Provider: anthropic, openai, openrouter, google
                                  [default: anthropic]
    $(echo -e "${GREEN}-m, --model${NC}") MODEL         Model name [default: claude-sonnet-4-5]
    $(echo -e "${GREEN}-t, --temperature${NC}") TEMP    Temperature 0.0-2.0 [default: 1.0]
    $(echo -e "${GREEN}-s, --stream${NC}")              Enable streaming [default: on]
    $(echo -e "${GREEN}-n, --no-stream${NC}")           Disable streaming
    $(echo -e "${GREEN}--system${NC}") PROMPT           Custom system prompt
    $(echo -e "${GREEN}--context${NC}") [LEVEL]         Context level: none, min, auto, full [default: auto]

    $(echo -e "${GREEN}--agent${NC}")                   Agent mode (execute commands)
    $(echo -e "${GREEN}--dry-run${NC}")                 Show plan without executing
    $(echo -e "${GREEN}--fn${NC}") NAME DESC            Generate shell function
    $(echo -e "${GREEN}--tools${NC}") LIST              Allowed tools for agent (curl,jq,git)

    $(echo -e "${GREEN}--index${NC}")                   Index current project
    $(echo -e "${GREEN}--save${NC}")                    Save conversation history
    $(echo -e "${GREEN}--load${NC}")                    Load conversation history
    $(echo -e "${GREEN}--clear${NC}")                   Clear conversation

    $(echo -e "${GREEN}--list-models${NC}")             List available models
    $(echo -e "${GREEN}--multiline${NC}")               Multi-line input mode (Ctrl+D to send)
    $(echo -e "${GREEN}--json${NC}")                    Output raw JSON

    $(echo -e "${GREEN}/gh-pr${NC}") [NUMBER]           Load GitHub PR context
    $(echo -e "${GREEN}/gh-pr-diff${NC}") [NUM]         Load GitHub PR diff
    $(echo -e "${GREEN}/gh-issue${NC}") NUMBER          Load GitHub issue context
    $(echo -e "${GREEN}/gh-prs${NC}") [STATE]           List PRs (open/closed/all)
    $(echo -e "${GREEN}/gh-issues${NC}") [STATE]        List issues (open/closed/all)
    $(echo -e "${GREEN}/gh-repo${NC}")                  Show repository info
    $(echo -e "${GREEN}/gh-help${NC}")                  GitHub commands help

    $(echo -e "${GREEN}keys${NC}") <action>             Manage API keys
      set <provider>         Set API key (prompted securely)
      list                   List configured keys
      remove <provider>      Remove API key
      path                   Show keys file location

    $(echo -e "${GREEN}-v, --version${NC}")             Show version
    $(echo -e "${GREEN}-h, --help${NC}")                Show this help

$(echo -e "${YELLOW}ENVIRONMENT VARIABLES (OPTIONAL):${NC}")
    $(echo -e "${GREEN}ANTHROPIC_API_KEY${NC}")         Anthropic API key (or use: ask keys set anthropic)
    $(echo -e "${GREEN}OPENAI_API_KEY${NC}")            OpenAI API key (or use: ask keys set openai)
    $(echo -e "${GREEN}OPENROUTER_API_KEY${NC}")        OpenRouter API key (or use: ask keys set openrouter)
    $(echo -e "${GREEN}GOOGLE_API_KEY${NC}")            Google Gemini API key (or use: ask keys set google)
    $(echo -e "${GREEN}DEEPSEEK_API_KEY${NC}")          DeepSeek API key (or use: ask keys set deepseek)
    $(echo -e "${GREEN}ASK_PROVIDER${NC}")              Default provider
    $(echo -e "${GREEN}ASK_MODEL${NC}")                 Default model

$(echo -e "${YELLOW}EXAMPLES:${NC}")
    # First time setup
    $(echo -e "${DIM}ask keys set anthropic${NC}")

    # Quick questions
    $(echo -e "${DIM}ask \"find all TODO comments in this repo\"${NC}")

    # Agent mode (with auto-approve)
    $(echo -e "${DIM}ask --agent \"create test directory\"${NC}")
    $(echo -e "${DIM}# Type 'a' to auto-approve low/medium risk commands${NC}")

    # Generate reusable functions
    $(echo -e "${DIM}ask --fn parse_nginx \"extract 500 errors from nginx logs\"${NC}")

    # Context-aware queries
    $(echo -e "${DIM}git diff | ask \"explain what changed and suggest improvements\"${NC}")

    # Git workflow helpers
    $(echo -e "${DIM}ask commit     # Generate semantic commit message${NC}")
    $(echo -e "${DIM}ask pr-review  # Review current branch vs main${NC}")

    # Interactive chat
    $(echo -e "${DIM}ask${NC}")

$(echo -e "${YELLOW}INTERACTIVE COMMANDS:${NC}")
    $(echo -e "${GREEN}/clear${NC}")              Clear conversation
    $(echo -e "${GREEN}/save${NC}")               Save conversation
    $(echo -e "${GREEN}/load${NC}")               Load conversation
    $(echo -e "${GREEN}/models${NC}")             List available models
    $(echo -e "${GREEN}/switch${NC}") [P] [M]    Switch provider/model
    $(echo -e "${GREEN}/context${NC}") [LEVEL]   Set context level
    $(echo -e "${GREEN}/gh-pr${NC}") [NUMBER]    Load GitHub PR context
    $(echo -e "${GREEN}/gh-issue${NC}") NUMBER   Load GitHub issue context
    $(echo -e "${GREEN}/help${NC}")               Show help
    $(echo -e "${GREEN}/exit${NC}") or $(echo -e "${GREEN}/quit${NC}")    Exit

$(echo -e "${YELLOW}AGENT MODE:${NC}")
    $(echo -e "${GREEN}y${NC}") - Ask for confirmation on each medium/high risk command
    $(echo -e "${GREEN}a${NC}") - Auto-approve low/medium risk (recommended)
    $(echo -e "${GREEN}n${NC}") - Cancel execution

    Risk levels:
    $(echo -e "${DIM}Low${NC}")    - Read-only (ls, cat, grep) - Auto-execute
    $(echo -e "${DIM}Medium${NC}") - Create/modify (mkdir, touch) - Confirm or auto with 'a'
    $(echo -e "${DIM}High${NC}")   - Delete/destroy (rm, dd) - Always confirm

$(echo -e "${YELLOW}CONTEXT LEVELS:${NC}")
    $(echo -e "${GREEN}none${NC}") - No context
    $(echo -e "${GREEN}min${NC}")  - Directory + date
    $(echo -e "${GREEN}auto${NC}") - + system info + git status (default)
    $(echo -e "${GREEN}full${NC}") - + shell + user + last command

$(echo -e "${YELLOW}SPECIAL MODES:${NC}")
    $(echo -e "${GREEN}ask commit${NC}")          Generate git commit message from staged changes
    $(echo -e "${GREEN}ask pr-review${NC}")       Review current branch changes
    $(echo -e "${GREEN}ask diagnose${NC}")        Diagnose last command failure

$(echo -e "${DIM}For more information, visit: https://github.com/elias-ba/ask${NC}")
EOF
}

init_config() {
    mkdir -p "$CONFIG_DIR" "$CACHE_DIR"
    [ ! -f "$HISTORY_FILE" ] && touch "$HISTORY_FILE"
    [ ! -f "$KEYS_FILE" ] && touch "$KEYS_FILE" && chmod 600 "$KEYS_FILE"
    [ ! -f "$FUNCTIONS_FILE" ] && cat > "$FUNCTIONS_FILE" <<'EOF'
# ask generated functions
# Source this file: source ~/.config/ask/functions.sh
# Or add to your ~/.bashrc: source ~/.config/ask/functions.sh

EOF

    load_keys
}

load_keys() {
    if [ -f "$KEYS_FILE" ]; then
        while IFS='=' read -r key value; do
            [[ "$key" =~ ^#.*$ || -z "$key" ]] && continue

            if [ -z "${!key}" ]; then
                export "$key=$value"
            fi
        done < "$KEYS_FILE"
    fi
}

manage_keys() {
    local action=$1
    local provider=$2
    local key=$3

    case $action in
        set)
            if [ -z "$provider" ]; then
                echo -e "${RED}Error: Provider required${NC}"
                echo "Usage: ask keys set <provider>"
                echo "Providers: anthropic, openai, openrouter, google"
                return 1
            fi

            local key_var=""
            case $provider in
                anthropic) key_var="ANTHROPIC_API_KEY" ;;
                openai) key_var="OPENAI_API_KEY" ;;
                openrouter) key_var="OPENROUTER_API_KEY" ;;
                google) key_var="GOOGLE_API_KEY" ;;
                deepseek) key_var="DEEPSEEK_API_KEY" ;;
                *)
                    echo -e "${RED}Unknown provider: $provider${NC}"
                    echo "Valid providers: anthropic, openai, openrouter, google"
                    return 1
                    ;;
            esac

            if [ -z "$key" ]; then
                echo -e "${CYAN}Enter your ${provider} API key:${NC}"
                read -rs key
                echo ""
            fi

            if [ -z "$key" ]; then
                echo -e "${RED}Error: No key provided${NC}"
                return 1
            fi

            if [ -f "$KEYS_FILE" ]; then
                sed -i.bak "/^${key_var}=/d" "$KEYS_FILE"
                rm -f "${KEYS_FILE}.bak"
            fi

            echo "${key_var}=${key}" >> "$KEYS_FILE"
            chmod 600 "$KEYS_FILE"

            export "${key_var}=${key}"

            echo -e "${GREEN}✓ ${provider} API key saved${NC}"
            echo -e "${DIM}Stored in: $KEYS_FILE${NC}"
            ;;

        list)
            echo -e "${CYAN}${BOLD}Configured API Keys:${NC}\n"

            local found=false
            for provider_name in anthropic openai openrouter google deepseek; do
                local key_var=""
                case $provider_name in
                    anthropic) key_var="ANTHROPIC_API_KEY" ;;
                    openai) key_var="OPENAI_API_KEY" ;;
                    openrouter) key_var="OPENROUTER_API_KEY" ;;
                    google) key_var="GOOGLE_API_KEY" ;;
                    deepseek) key_var="DEEPSEEK_API_KEY" ;;
                esac

                local key_value="${!key_var}"

                if [ -z "$key_value" ] && [ -f "$KEYS_FILE" ]; then
                    key_value=$(grep "^${key_var}=" "$KEYS_FILE" 2>/dev/null | cut -d'=' -f2)
                fi

                if [ -n "$key_value" ]; then
                    local masked_key="${key_value:0:8}...${key_value: -4}"
                    local source="env"
                    if grep -q "^${key_var}=" "$KEYS_FILE" 2>/dev/null; then
                        source="file"
                    fi
                    echo -e "${GREEN}✓${NC} ${provider_name}: ${masked_key} ${DIM}(${source})${NC}"
                    found=true
                else
                    echo -e "${DIM}○${NC} ${provider_name}: ${DIM}not set${NC}"
                fi
            done

            if [ "$found" = false ]; then
                echo -e "\n${YELLOW}No API keys configured${NC}"
                echo -e "Set a key with: ${CYAN}ask keys set <provider>${NC}"
            fi
            ;;

        remove)
            if [ -z "$provider" ]; then
                echo -e "${RED}Error: Provider required${NC}"
                echo "Usage: ask keys remove <provider>"
                return 1
            fi

            local key_var=""
            case $provider in
                anthropic) key_var="ANTHROPIC_API_KEY" ;;
                openai) key_var="OPENAI_API_KEY" ;;
                openrouter) key_var="OPENROUTER_API_KEY" ;;
                google) key_var="GOOGLE_API_KEY" ;;
                deepseek) key_var="DEEPSEEK_API_KEY" ;;
                *)
                    echo -e "${RED}Unknown provider: $provider${NC}"
                    return 1
                    ;;
            esac

            if [ -f "$KEYS_FILE" ]; then
                sed -i.bak "/^${key_var}=/d" "$KEYS_FILE"
                rm -f "${KEYS_FILE}.bak"
            fi

            unset "$key_var"

            echo -e "${GREEN}✓ ${provider} API key removed${NC}"
            ;;

        path)
            echo "$KEYS_FILE"
            ;;

        *)
            echo -e "${YELLOW}Usage:${NC}"
            echo "  ask keys set <provider>     Set API key for provider"
            echo "  ask keys list               List configured keys"
            echo "  ask keys remove <provider>  Remove API key"
            echo "  ask keys path               Show keys file location"
            echo ""
            echo -e "${YELLOW}Providers:${NC} anthropic, openai, openrouter, google"
            ;;
    esac
}

check_dependencies() {
    local missing=()
    for cmd in jq curl; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("$cmd")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "${RED}Error: Missing dependencies: ${missing[*]}${NC}"
        echo "Install with: brew install ${missing[*]} (or apt-get/yum/pacman)"
        exit 1
    fi
}

check_api_key() {
    local provider=$1
    local key_var=""

    case $provider in
        anthropic) key_var="ANTHROPIC_API_KEY" ;;
        openai) key_var="OPENAI_API_KEY" ;;
        openrouter) key_var="OPENROUTER_API_KEY" ;;
        google) key_var="GOOGLE_API_KEY" ;;
        deepseek) key_var="DEEPSEEK_API_KEY" ;;
    esac

    if [ -z "${!key_var}" ]; then
        echo -e "${RED}Error: $key_var not set${NC}\n"
        echo -e "${BOLD}Set up your API key:${NC}"
        echo -e "  ${CYAN}ask keys set $provider${NC}"
        echo -e ""
        echo -e "${BOLD}Or use environment variable:${NC}"
        echo -e "  ${CYAN}export $key_var='your-key-here'${NC}"
        echo -e ""
        echo -e "${BOLD}Get an API key:${NC}"
        case $provider in
            anthropic)
                echo -e "  ${DIM}https://console.anthropic.com/${NC}"
                ;;
            openai)
                echo -e "  ${DIM}https://platform.openai.com/api-keys${NC}"
                ;;
            openrouter)
                echo -e "  ${DIM}https://openrouter.ai/keys${NC}"
                ;;
            google)
                echo -e "  ${DIM}https://aistudio.google.com/apikey${NC}"
                ;;
            deepseek)
                echo -e "  ${DIM}https://platform.deepseek.com/${NC}"
                ;;
        esac
        exit 1
    fi
}

list_models() {
    local provider=$1
    echo -e "${CYAN}Available models for ${BOLD}${provider}${NC}:"
    local models=$(get_models "$provider")
    local IFS=','
    for model in $models; do
        echo -e "  ${GREEN}→${NC} $model"
    done
}

gather_context() {
    local level=${1:-auto}
    local context=""

    case $level in
        min)
            context="Working directory: $(pwd)\n"
            context+="Date: $(date '+%Y-%m-%d %H:%M:%S')\n"
            ;;
        auto)
            context="System: $(uname -s) $(uname -m)\n"
            context+="Working directory: $(pwd)\n"
            context+="Date: $(date '+%Y-%m-%d %H:%M:%S')\n"

            if git rev-parse --git-dir &>/dev/null; then
                context+="Git branch: $(git branch --show-current 2>/dev/null)\n"
                local status=$(git status --short 2>/dev/null | head -5)
                [ -n "$status" ] && context+="Git status:\n$status\n"
            fi
            ;;
        full)
            context=$(gather_context auto)
            context+="Shell: $SHELL\n"
            context+="User: $USER\n"
            local last_cmd=$(fc -ln -1 2>/dev/null | sed 's/^[[:space:]]*//')
            [ -n "$last_cmd" ] && context+="Last command: $last_cmd\n"
            ;;
    esac

    echo "$context"
}

check_github_cli() {
    if ! command -v gh &>/dev/null; then
        echo -e "${RED}Error: GitHub CLI (gh) is not installed${NC}" >&2
        echo -e "${YELLOW}Install with:${NC}" >&2
        echo -e "  macOS:   ${DIM}brew install gh${NC}" >&2
        echo -e "  Linux:   ${DIM}See https://cli.github.com/manual/installation${NC}" >&2
        return 1
    fi

    if ! gh auth status &>/dev/null; then
        echo -e "${RED}Error: Not authenticated with GitHub${NC}" >&2
        echo -e "${YELLOW}Authenticate with: ${CYAN}gh auth login${NC}" >&2
        return 1
    fi

    return 0
}

check_github_repo() {
    if ! git rev-parse --git-dir &>/dev/null; then
        echo -e "${RED}Error: Not in a git repository${NC}" >&2
        return 1
    fi

    local remote_url=$(git config --get remote.origin.url 2>/dev/null)
    if [[ ! "$remote_url" =~ github\.com ]]; then
        echo -e "${RED}Error: No GitHub remote found${NC}" >&2
        echo -e "${DIM}Current remote: $remote_url${NC}" >&2
        return 1
    fi

    return 0
}

gather_github_context() {
    local type=$1
    local id=$2
    local context=""

    check_github_cli || return 1
    check_github_repo || return 1

    case $type in
        pr)
            if [ -n "$id" ] && [ "$id" != "current" ]; then
                local pr_data=$(gh pr view "$id" --json number,title,body,author,state,isDraft,additions,deletions,labels,reviewDecision 2>&1)
                local exit_code=$?

                if [ $exit_code -ne 0 ]; then
                    echo -e "${RED}Error: Could not fetch PR #${id}${NC}" >&2
                    echo -e "${DIM}$pr_data${NC}" >&2
                    return 1
                fi

                context+="=== GitHub Pull Request #$id ===\n"
                context+="$(echo "$pr_data" | jq -r '
                    "Title: \(.title)",
                    "Author: \(.author.login)",
                    "State: \(.state)" + (if .isDraft then " (Draft)" else "" end),
                    "Review: \(.reviewDecision // "Not reviewed")",
                    "Changes: +\(.additions)/-\(.deletions)",
                    "Labels: \(if .labels | length > 0 then ([.labels[].name] | join(", ")) else "none" end)",
                    "",
                    "Description:",
                    "\(.body // "No description provided")"
                ')\n\n"

            else
                local pr_data=$(gh pr view --json number,title,body,author,state,isDraft,additions,deletions,labels,reviewDecision,commits 2>&1)
                local exit_code=$?

                if [ $exit_code -ne 0 ]; then
                    echo -e "${YELLOW}No PR found for current branch${NC}" >&2
                    return 1
                fi

                local pr_num=$(echo "$pr_data" | jq -r '.number')
                context+="=== Current Branch PR #$pr_num ===\n"
                context+="$(echo "$pr_data" | jq -r '
                    "Title: \(.title)",
                    "Author: \(.author.login)",
                    "State: \(.state)" + (if .isDraft then " (Draft)" else "" end),
                    "Review: \(.reviewDecision // "Not reviewed")",
                    "Changes: +\(.additions)/-\(.deletions)",
                    "Commits: \(.commits | length)",
                    "Labels: \(if .labels | length > 0 then ([.labels[].name] | join(", ")) else "none" end)",
                    "",
                    "Description:",
                    "\(.body // "No description provided")"
                ')\n\n"
            fi
            ;;

        issue)
            if [ -z "$id" ]; then
                echo -e "${RED}Error: Issue number required${NC}" >&2
                echo -e "Usage: /gh-issue <number>" >&2
                return 1
            fi

            local issue_data=$(gh issue view "$id" --json number,title,body,author,state,labels,assignees,comments 2>&1)
            local exit_code=$?

            if [ $exit_code -ne 0 ]; then
                echo -e "${RED}Error: Could not fetch issue #${id}${NC}" >&2
                echo -e "${DIM}$issue_data${NC}" >&2
                return 1
            fi

            context+="=== GitHub Issue #$id ===\n"
            context+="$(echo "$issue_data" | jq -r '
                "Title: \(.title)",
                "Author: \(.author.login)",
                "State: \(.state)",
                "Assignees: \(if .assignees | length > 0 then ([.assignees[].login] | join(", ")) else "none" end)",
                "Labels: \(if .labels | length > 0 then ([.labels[].name] | join(", ")) else "none" end)",
                "Comments: \(.comments | length)",
                "",
                "Description:",
                "\(.body // "No description provided")"
            ')\n\n"

            local comment_count=$(echo "$issue_data" | jq '.comments | length')
            if [ "$comment_count" -gt 0 ]; then
                context+="Recent Comments:\n"
                context+="$(echo "$issue_data" | jq -r '
                    .comments[-3:] | .[] |
                    "---\n\(.author.login) on \(.createdAt[:10]):\n\(.body)\n"
                ')\n"
            fi
            ;;

        pr-diff)
            if [ -z "$id" ]; then
                local diff=$(gh pr diff 2>&1)
            else
                local diff=$(gh pr diff "$id" 2>&1)
            fi

            if [ $? -ne 0 ]; then
                echo -e "${RED}Error: Could not fetch PR diff${NC}" >&2
                return 1
            fi

            context+="=== PR Changes ===\n"
            context+="\`\`\`diff\n$diff\n\`\`\`\n\n"
            ;;

        pr-list)
            local state="${id:-open}"
            local prs=$(gh pr list --state "$state" --json number,title,author,updatedAt --limit 10 2>&1)

            if [ $? -ne 0 ]; then
                echo -e "${RED}Error: Could not list PRs${NC}" >&2
                return 1
            fi

            context+="=== ${state^} Pull Requests ===\n"
            context+="$(echo "$prs" | jq -r '.[] | "#\(.number): \(.title) (@\(.author.login)) - Updated: \(.updatedAt[:10])"')\n\n"
            ;;

        issue-list)
            local state="${id:-open}"
            local issues=$(gh issue list --state "$state" --json number,title,author,updatedAt --limit 10 2>&1)

            if [ $? -ne 0 ]; then
                echo -e "${RED}Error: Could not list issues${NC}" >&2
                return 1
            fi

            context+="=== ${state^} Issues ===\n"
            context+="$(echo "$issues" | jq -r '.[] | "#\(.number): \(.title) (@\(.author.login)) - Updated: \(.updatedAt[:10])"')\n\n"
            ;;

        repo)
            local repo_data=$(gh repo view --json name,description,stargazerCount,forkCount,primaryLanguage,defaultBranchRef 2>&1)

            if [ $? -ne 0 ]; then
                echo -e "${RED}Error: Could not fetch repo info${NC}" >&2
                return 1
            fi

            context+="=== Repository Info ===\n"
            context+="$(echo "$repo_data" | jq -r '
                "Name: \(.name)",
                "Description: \(.description // "No description")",
                "Stars: \(.stargazerCount)",
                "Forks: \(.forkCount)",
                "Language: \(.primaryLanguage.name // "Unknown")",
                "Default Branch: \(.defaultBranchRef.name)"
            ')\n\n"
            ;;
    esac

    echo -e "$context"
}

handle_github_command() {
    local cmd=$1
    shift
    local args=("$@")

    case $cmd in
        /gh-pr)
            local pr_num="${args[0]}"
            echo -e "${CYAN}Fetching PR context...${NC}"
            local gh_ctx=$(gather_github_context "pr" "$pr_num")
            if [ $? -eq 0 ] && [ -n "$gh_ctx" ]; then
                echo -e "${GREEN}✓ Loaded PR context${NC}"
                GH_CONTEXT="$gh_ctx"
            fi
            ;;

        /gh-pr-diff)
            local pr_num="${args[0]}"
            echo -e "${CYAN}Fetching PR diff...${NC}"
            local gh_ctx=$(gather_github_context "pr-diff" "$pr_num")
            if [ $? -eq 0 ] && [ -n "$gh_ctx" ]; then
                echo -e "${GREEN}✓ Loaded PR diff${NC}"
                GH_CONTEXT="$gh_ctx"
            fi
            ;;

        /gh-issue)
            local issue_num="${args[0]}"
            if [ -z "$issue_num" ]; then
                echo -e "${RED}Error: Issue number required${NC}"
                echo "Usage: /gh-issue <number>"
                return
            fi
            echo -e "${CYAN}Fetching issue context...${NC}"
            local gh_ctx=$(gather_github_context "issue" "$issue_num")
            if [ $? -eq 0 ] && [ -n "$gh_ctx" ]; then
                echo -e "${GREEN}✓ Loaded issue #${issue_num} context${NC}"
                GH_CONTEXT="$gh_ctx"
            fi
            ;;

        /gh-prs)
            local state="${args[0]:-open}"
            echo -e "${CYAN}Listing ${state} PRs...${NC}"
            local gh_ctx=$(gather_github_context "pr-list" "$state")
            if [ $? -eq 0 ] && [ -n "$gh_ctx" ]; then
                echo "$gh_ctx"
            fi
            ;;

        /gh-issues)
            local state="${args[0]:-open}"
            echo -e "${CYAN}Listing ${state} issues...${NC}"
            local gh_ctx=$(gather_github_context "issue-list" "$state")
            if [ $? -eq 0 ] && [ -n "$gh_ctx" ]; then
                echo "$gh_ctx"
            fi
            ;;

        /gh-repo)
            echo -e "${CYAN}Fetching repository info...${NC}"
            local gh_ctx=$(gather_github_context "repo" "")
            if [ $? -eq 0 ] && [ -n "$gh_ctx" ]; then
                echo "$gh_ctx"
            fi
            ;;

        /gh-help)
            cat <<EOF
${CYAN}${BOLD}GitHub Commands:${NC}

${GREEN}/gh-pr [NUMBER]${NC}        Load PR context (current branch if no number)
${GREEN}/gh-pr-diff [NUMBER]${NC}   Load PR diff (current branch if no number)
${GREEN}/gh-issue NUMBER${NC}       Load issue context
${GREEN}/gh-prs [STATE]${NC}        List PRs (open/closed/all)
${GREEN}/gh-issues [STATE]${NC}     List issues (open/closed/all)
${GREEN}/gh-repo${NC}               Show repository info
${GREEN}/gh-help${NC}               Show this help

${YELLOW}Examples:${NC}
  ${DIM}/gh-pr 123          ${NC}Load PR #123
  ${DIM}/gh-pr              ${NC}Load current branch PR
  ${DIM}/gh-issue 42        ${NC}Load issue #42
  ${DIM}/gh-prs closed      ${NC}List closed PRs
  ${DIM}/gh-repo            ${NC}Show repo info

${YELLOW}Prerequisites:${NC}
  ${DIM}gh auth login       ${NC}Authenticate with GitHub
EOF
            ;;
    esac
}

handle_stream() {
    local provider=$1
    local buffer=""

    while IFS= read -r line; do
        [[ -z "$line" ]] && continue

        line="${line#data: }"

        [[ "$line" == "[DONE]" ]] && break

        echo "$line" | jq empty 2>/dev/null || continue

        case $provider in
            anthropic)
                local type=$(echo "$line" | jq -r '.type // empty' 2>/dev/null)
                if [[ "$type" == "content_block_delta" ]]; then
                    local text=$(echo "$line" | jq -r '.delta.text // empty' 2>/dev/null)
                    if [[ -n "$text" && "$text" != "null" ]]; then
                        printf "%s" "$text"
                    fi
                fi
                ;;
            openai|openrouter|deepseek)
                local content=$(echo "$line" | jq -r '.choices[0].delta.content // empty' 2>/dev/null)
                if [[ -n "$content" && "$content" != "null" ]]; then
                    printf "%s" "$content"
                fi
                ;;
            google)
                local text=$(echo "$line" | jq -r '.candidates[0].content.parts[0].text // empty' 2>/dev/null)
                if [[ -n "$text" && "$text" != "null" ]]; then
                    printf "%s" "$text"
                fi
                ;;
        esac
    done
    echo ""
}

call_api() {
    local provider=$1
    local model=$2
    local message=$3
    local stream=$4
    local system_prompt=${5:-"You are a helpful AI assistant for the command line. Provide concise, accurate answers. When writing code or commands, ensure they are correct and safe."}
    local temperature=${6:-1.0}
    local max_tokens=${7:-4096}

    local api_url=$(get_api_url "$provider")
    local response=""

    local messages_json="$CONVERSATION_JSON"
    [ -z "$messages_json" ] && messages_json='[]'
    messages_json=$(echo "$messages_json" | jq ". + [{\"role\": \"user\", \"content\": $(echo "$message" | jq -Rs .)}]")

    if [ -t 1 ]; then
        show_thinking
    fi

    case $provider in
        anthropic)
            local data=$(jq -n \
                --arg model "$model" \
                --argjson messages "$messages_json" \
                --argjson stream "$stream" \
                --arg system "$system_prompt" \
                --argjson max_tokens "$max_tokens" \
                '{
                    model: $model,
                    messages: $messages,
                    stream: $stream,
                    system: $system,
                    max_tokens: $max_tokens
                }')

            if [ "$stream" = "true" ]; then
                [ -t 1 ] && clear_thinking
                curl -sN "$api_url" \
                    -H "Content-Type: application/json" \
                    -H "x-api-key: ${ANTHROPIC_API_KEY}" \
                    -H "anthropic-version: 2023-06-01" \
                    -d "$data" | handle_stream "$provider"
            else
                response=$(curl -s "$api_url" \
                    -H "Content-Type: application/json" \
                    -H "x-api-key: ${ANTHROPIC_API_KEY}" \
                    -H "anthropic-version: 2023-06-01" \
                    -d "$data")
                [ -t 1 ] && clear_thinking
                echo "$response" | jq -r '.content[0].text'
            fi
            ;;

        openai|openrouter|deepseek)
            local key_header=""
            [ "$provider" = "openai" ] && key_header="Authorization: Bearer ${OPENAI_API_KEY}"
            [ "$provider" = "openrouter" ] && key_header="Authorization: Bearer ${OPENROUTER_API_KEY}"
            [ "$provider" = "deepseek" ] && key_header="Authorization: Bearer ${DEEPSEEK_API_KEY}"

            if [ -n "$system_prompt" ]; then
                messages_json=$(echo "$messages_json" | jq "[{\"role\": \"system\", \"content\": \"$system_prompt\"}] + .")
            fi

            local data=$(jq -n \
                --arg model "$model" \
                --argjson messages "$messages_json" \
                --argjson stream "$stream" \
                --argjson temperature "$temperature" \
                --argjson max_tokens "$max_tokens" \
                '{
                    model: $model,
                    messages: $messages,
                    stream: $stream,
                    temperature: $temperature,
                    max_tokens: $max_tokens
                }')

            if [ "$stream" = "true" ]; then
                [ -t 1 ] && clear_thinking
                curl -sN "$api_url" \
                    -H "Content-Type: application/json" \
                    -H "$key_header" \
                    -d "$data" | handle_stream "$provider"
            else
                response=$(curl -s "$api_url" \
                    -H "Content-Type: application/json" \
                    -H "$key_header" \
                    -d "$data")
                [ -t 1 ] && clear_thinking
                echo "$response" | jq -r '.choices[0].message.content'
            fi
            ;;

        google)
            # Convert messages from OpenAI format to Gemini format
            # OpenAI: {"role": "user", "content": "..."}
            # Gemini: {"role": "user", "parts": [{"text": "..."}]}
            # Also convert "assistant" role to "model"
            local gemini_contents=$(echo "$messages_json" | jq '[.[] | {
                role: (if .role == "assistant" then "model" else .role end),
                parts: [{text: .content}]
            }]')

            # Build the API URL with model name
            local endpoint="generateContent"
            [ "$stream" = "true" ] && endpoint="streamGenerateContent?alt=sse"
            local full_url="${api_url}/${model}:${endpoint}"

            # Build request data with system_instruction
            local data=$(jq -n \
                --argjson contents "$gemini_contents" \
                --arg system "$system_prompt" \
                '{
                    system_instruction: {
                        parts: [{text: $system}]
                    },
                    contents: $contents
                }')

            if [ "$stream" = "true" ]; then
                [ -t 1 ] && clear_thinking
                curl -sN "$full_url" \
                    -H "Content-Type: application/json" \
                    -H "x-goog-api-key: ${GOOGLE_API_KEY}" \
                    -d "$data" | handle_stream "$provider"
            else
                response=$(curl -s "$full_url" \
                    -H "Content-Type: application/json" \
                    -H "x-goog-api-key: ${GOOGLE_API_KEY}" \
                    -d "$data")
                [ -t 1 ] && clear_thinking

                # Check for API errors
                local error_msg=$(echo "$response" | jq -r '.error.message // empty' 2>/dev/null)
                if [ -n "$error_msg" ]; then
                    local error_code=$(echo "$response" | jq -r '.error.code // empty' 2>/dev/null)
                    echo -e "${RED}Error from Gemini API (code $error_code):${NC}" >&2
                    echo -e "${DIM}$error_msg${NC}" >&2
                    if [[ "$error_msg" == *"quota"* ]] || [[ "$error_code" == "429" ]]; then
                        echo -e "${YELLOW}Tip: gemini-3-pro and gemini-2.5-pro may require a paid plan.${NC}" >&2
                        echo -e "${YELLOW}Try: ask -p google -m gemini-2.5-flash \"your question\"${NC}" >&2
                    fi
                    return 1
                fi

                echo "$response" | jq -r '.candidates[0].content.parts[0].text'
            fi
            ;;
    esac
}

generate_function() {
    local fn_name=$1
    local description=$2
    local provider=$3
    local model=$4

    echo -e "${CYAN}Generating function: ${BOLD}${fn_name}${NC}"

    local prompt="Generate a bash function named '$fn_name' that: $description

Requirements:
- Function must be safe and handle errors
- Include helpful comments
- Use standard bash/unix tools
- Return ONLY the function code, no explanation
- Start with: ${fn_name}() {"

    local code=$(call_api "$provider" "$model" "$prompt" false "You are an expert bash programmer. Generate clean, safe, well-commented bash functions." 1.0 2048)

    if ! echo "$code" | bash -n 2>/dev/null; then
        echo -e "${RED}Generated function has syntax errors${NC}"
        return 1
    fi

    echo -e "\n${GREEN}Generated function:${NC}\n"
    echo "$code"

    echo -e "\n${YELLOW}Save this function? (y/n/e to edit)${NC}"
    read -r reply

    case $reply in
        y|Y)
            echo -e "\n# generated by ask on $(date)" >> "$FUNCTIONS_FILE"
            echo "$code" >> "$FUNCTIONS_FILE"
            echo -e "\n${GREEN}✓ Function saved to $FUNCTIONS_FILE${NC}"
            echo -e "Source it with: ${DIM}source $FUNCTIONS_FILE${NC}"
            ;;
        e|E)
            local tmp_file=$(mktemp)
            echo "$code" > "$tmp_file"
            ${EDITOR:-vi} "$tmp_file"
            echo -e "\n# generated by ask on $(date)" >> "$FUNCTIONS_FILE"
            cat "$tmp_file" >> "$FUNCTIONS_FILE"
            rm "$tmp_file"
            echo -e "${GREEN}✓ Function saved${NC}"
            ;;
        *)
            echo -e "${YELLOW}Function not saved${NC}"
            ;;
    esac
}

agent_mode() {
    local goal=$1
    local dry_run=$2
    local provider=$3
    local model=$4

    echo -e "${MAGENTA}agent mode${NC}"
    echo -e "Goal: ${BOLD}${goal}${NC}\n"

    local context=$(gather_context full)
    local prompt="You are a bash automation agent. Create a step-by-step plan to: $goal

Context:
$context

Return a JSON array of steps with this structure:
[
  {
    \"step\": 1,
    \"description\": \"What this step does\",
    \"command\": \"actual bash command\",
    \"risk\": \"low|medium|high\"
  }
]

Guidelines:
- Use only safe, standard unix commands
- Each command should be independently executable
- Mark anything that DELETES or DESTROYS data as 'high' risk
- Mark file creation/modification as 'medium' risk
- Mark read-only operations as 'low' risk
- Be conservative: when in doubt, mark as higher risk"

    echo -e "${CYAN}Creating execution plan...${NC}\n"
    local plan=$(call_api "$provider" "$model" "$prompt" false "You are a bash automation expert. Always return valid JSON." 0.7 2048)

    plan=$(echo "$plan" | sed -n '/\[/,/\]/p')

    if ! echo "$plan" | jq empty 2>/dev/null; then
        echo -e "${RED}Failed to generate valid execution plan${NC}"
        return 1
    fi

    echo -e "${BOLD}Execution Plan:${NC}"
    echo "$plan" | jq -r '.[] | "[\(.step)] \(.description)\n    Command: \(.command)\n    Risk: \(.risk)\n"'

    if [ "$dry_run" = true ]; then
        echo -e "${YELLOW}🏜️  Dry run - no commands executed${NC}"
        return 0
    fi

    echo -e "${YELLOW}Execute this plan? (y/n/a for auto-approve medium+low)${NC}"
    read -r confirm </dev/tty

    local auto_approve=false
    if [[ $confirm =~ ^[Aa]$ ]]; then
        auto_approve=true
        echo -e "${GREEN}✓ Auto-approving low and medium risk commands${NC}\n"
    elif [[ ! $confirm =~ ^[Yy]$ ]]; then
        return 0
    fi

    local plan_file=$(mktemp)
    echo "$plan" | jq -c '.[]' > "$plan_file"

    while IFS= read -r step; do
        local cmd=$(echo "$step" | jq -r '.command')
        local desc=$(echo "$step" | jq -r '.description')
        local risk=$(echo "$step" | jq -r '.risk')

        echo -e "\n${CYAN}→ $desc${NC}"
        echo -e "${DIM}$cmd${NC}"

        local should_execute=true

        if [ "$risk" = "high" ]; then
            echo -e "${RED}⚠️  High risk command - requires confirmation${NC}"
            echo -e "${YELLOW}Execute? (y/n)${NC}"
            read -r confirm </dev/tty
            [[ ! $confirm =~ ^[Yy]$ ]] && should_execute=false
        elif [ "$risk" = "medium" ] && [ "$auto_approve" = false ]; then
            echo -e "${YELLOW}⚠️  Medium risk - confirm? (y/n)${NC}"
            read -r confirm </dev/tty
            [[ ! $confirm =~ ^[Yy]$ ]] && should_execute=false
        fi

        if [ "$should_execute" = true ]; then
            eval "$cmd"
            local exit_code=$?

            if [ $exit_code -eq 0 ]; then
                echo -e "${GREEN}✓ Success${NC}"
            else
                echo -e "${RED}✗ Failed (exit code: $exit_code)${NC}"
                echo -e "${YELLOW}Continue with next step? (y/n)${NC}"
                read -r confirm </dev/tty
                [[ ! $confirm =~ ^[Yy]$ ]] && break
            fi
        else
            echo -e "${YELLOW}⊘ Skipped${NC}"
        fi
    done < "$plan_file"

    rm -f "$plan_file"
}

git_commit_helper() {
    if ! git rev-parse --git-dir &>/dev/null; then
        echo -e "${RED}Not in a git repository${NC}"
        return 1
    fi

    local diff=$(git diff --cached)
    if [ -z "$diff" ]; then
        echo -e "${YELLOW}No staged changes. Stage changes with: git add${NC}"
        return 1
    fi

    echo -e "${CYAN}Analyzing staged changes...${NC}\n"

    local prompt="Generate a concise semantic commit message for these changes. Follow conventional commits format: type(scope): description

Only return the commit message, nothing else.

Changes:
\`\`\`
$diff
\`\`\`"

    local msg=$(call_api "$DEFAULT_PROVIDER" "$DEFAULT_MODEL" "$prompt" false "You are a git expert. Generate concise, semantic commit messages in conventional commits format. Return ONLY the commit message, no explanation or markdown." 0.7 1024)

    msg=$(echo "$msg" | sed 's/^[`"]*//g' | sed 's/[`"]*$//g' | head -1)

    if [ -z "$msg" ] || [ "$msg" = "null" ]; then
        echo -e "${RED}Failed to generate commit message${NC}"
        return 1
    fi

    echo -e "${GREEN}Suggested commit message:${NC}"
    echo -e "${BOLD}$msg${NC}\n"

    echo -e "${YELLOW}Use this message? (y/n/e to edit)${NC}"
    read -r reply

    case $reply in
        y|Y)
            git commit -m "$msg"
            ;;
        e|E)
            local tmp_file=$(mktemp)
            echo "$msg" > "$tmp_file"
            ${EDITOR:-vi} "$tmp_file"
            git commit -F "$tmp_file"
            rm "$tmp_file"
            ;;
        *)
            echo -e "${YELLOW}Commit cancelled${NC}"
            ;;
    esac
}

save_history() {
    echo "$CONVERSATION_JSON" > "$HISTORY_FILE"
    echo -e "${GREEN}✓ Conversation saved${NC}"
}

load_history() {
    if [ -f "$HISTORY_FILE" ]; then
        CONVERSATION_JSON=$(cat "$HISTORY_FILE")
        local msg_count=$(echo "$CONVERSATION_JSON" | jq 'length')
        echo -e "${GREEN}✓ Loaded ${msg_count} messages${NC}"
    else
        echo -e "${YELLOW}No history found${NC}"
    fi
}

interactive_mode() {
    local provider=$1
    local model=$2
    local stream=$3
    local context_level=$4

    GH_CONTEXT=""

    show_banner
    echo -e "${DIM}Provider: ${GREEN}${provider}${NC}${DIM} | Model: ${GREEN}${model}${NC}"
    echo -e "${DIM}Streaming: ${GREEN}${stream}${NC}${DIM} | Context: ${GREEN}${context_level}${NC}\n"
    echo -e "${YELLOW}Type your message (or /help for commands)${NC}\n"

    while true; do
        echo -ne "${BLUE}ask>${NC} "
        read -r input

        case $input in
            /exit|/quit|exit|quit)
                echo -e "${CYAN}Goodbye!${NC}"
                exit 0
                ;;
            /clear)
                CONVERSATION_JSON='[]'
                echo -e "${GREEN}✓ Conversation cleared${NC}"
                continue
                ;;
            /gh-*)
                local gh_cmd=$(echo "$input" | awk '{print $1}')
                local gh_args_raw=$(echo "$input" | cut -s -d' ' -f2-)

                if [ -n "$gh_args_raw" ]; then
                    read -ra gh_args_array <<< "$gh_args_raw"
                    handle_github_command "$gh_cmd" "${gh_args_array[@]}"
                else
                    handle_github_command "$gh_cmd"
                fi
                continue
                ;;
            /save)
                save_history
                continue
                ;;
            /load)
                load_history
                continue
                ;;
            /models)
                list_models "$provider"
                continue
                ;;
            /switch*)
                read -r _ new_provider new_model <<< "$input"
                [ -n "$new_provider" ] && provider="$new_provider" && check_api_key "$provider"
                [ -n "$new_model" ] && model="$new_model"
                echo -e "${GREEN}✓ Switched to ${provider}/${model}${NC}"
                continue
                ;;
            /context*)
                read -r _ new_level <<< "$input"
                [ -n "$new_level" ] && context_level="$new_level"
                echo -e "${GREEN}✓ Context level: ${context_level}${NC}"
                continue
                ;;
            /help)
                show_help
                continue
                ;;
            "")
                continue
                ;;
        esac

        local full_prompt="$input"
        if [ -n "$GH_CONTEXT" ]; then
            full_prompt="${GH_CONTEXT}${input}"
            GH_CONTEXT=""
        fi
        if [ "$context_level" != "none" ]; then
            local ctx=$(gather_context "$context_level")
            if [ -n "$ctx" ]; then
                full_prompt="Context about my system:\n${ctx}\n\nQuestion: ${full_prompt}"
            fi
        fi

        [ -z "$CONVERSATION_JSON" ] && CONVERSATION_JSON='[]'
        CONVERSATION_JSON=$(echo "$CONVERSATION_JSON" | jq ". + [{\"role\":\"user\",\"content\":$(echo "$full_prompt" | jq -Rs .)}]")

        if [ "$stream" = "true" ]; then
            call_api "$provider" "$model" "$full_prompt" "$stream" "" "" ""
            echo ""
            CONVERSATION_JSON=$(echo "$CONVERSATION_JSON" | jq ". + [{\"role\":\"assistant\",\"content\":\"[Response streamed]\"}]")
        else
            local response=$(call_api "$provider" "$model" "$full_prompt" "$stream" "" "" "")
            if [ -n "$response" ]; then
                echo "$response"
                echo ""
                CONVERSATION_JSON=$(echo "$CONVERSATION_JSON" | jq ". + [{\"role\":\"assistant\",\"content\":$(echo "$response" | jq -Rs .)}]")
            fi
        fi

        local msg_count=$(echo "$CONVERSATION_JSON" | jq 'length')
        if [ "$msg_count" -gt $((MAX_HISTORY * 2)) ]; then
            CONVERSATION_JSON=$(echo "$CONVERSATION_JSON" | jq '.[2:]')
        fi
    done
}

main() {
    local provider="${ASK_PROVIDER:-$DEFAULT_PROVIDER}"
    local model="${ASK_MODEL:-}"
    local model_specified=false
    local stream="$STREAM_ENABLED"
    local temperature="$DEFAULT_TEMPERATURE"
    local max_tokens="$DEFAULT_MAX_TOKENS"
    local system_prompt=""
    local context_level="auto"
    local mode="chat"
    local prompt=""
    local gh_pr=""
    local gh_issue=""

    while [[ $# -gt 0 ]]; do
        case $1 in
            -p|--provider)
                provider="$2"
                shift 2
                ;;
            -m|--model)
                model="$2"
                model_specified=true
                shift 2
                ;;
            -t|--temperature)
                temperature="$2"
                shift 2
                ;;
            -s|--stream)
                stream=true
                shift
                ;;
            -n|--no-stream)
                stream=false
                shift
                ;;
            --system)
                system_prompt="$2"
                shift 2
                ;;
            --context)
                context_level="${2:-auto}"
                shift 2
                ;;
            --agent)
                mode="agent"
                shift
                ;;
            --dry-run)
                mode="agent"
                dry_run=true
                shift
                ;;
            --fn)
                mode="function"
                fn_name="$2"
                fn_desc="$3"
                shift 3
                ;;
            --list-models)
                list_models "$provider"
                exit 0
                ;;
            --save)
                save_history
                exit 0
                ;;
            --load)
                load_history
                exit 0
                ;;
            --clear)
                rm -f "$HISTORY_FILE"
                echo -e "${GREEN}✓ History cleared${NC}"
                exit 0
                ;;
            -v|--version)
                echo "ask v${VERSION}"
                exit 0
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            commit)
                git_commit_helper
                exit 0
                ;;
            keys)
                check_dependencies
                init_config
                shift
                manage_keys "$@"
                exit 0
                ;;
            --gh-pr)
                gh_pr="${2:-current}"
                shift
                [ "$gh_pr" != "current" ] && shift
                ;;
            --gh-issue)
                gh_issue="$2"
                shift 2
                ;;
            -*)
                echo -e "${RED}Unknown option: $1${NC}"
                echo "Try 'ask --help' for more information"
                exit 1
                ;;
            *)
                prompt="$*"
                break
                ;;
        esac
    done

    check_dependencies
    init_config

    # Auto-select default model based on provider if not specified
    if [ -z "$model" ] || [ "$model_specified" = false ]; then
        model=$(get_default_model "$provider")
    fi

    check_api_key "$provider"

    local piped_input=""
    if [ ! -t 0 ]; then
        piped_input=$(cat)
    fi

    if [ -n "$piped_input" ] && [ -n "$prompt" ]; then
        prompt="Input:\n\`\`\`\n${piped_input}\n\`\`\`\n\nQuestion: ${prompt}"
    elif [ -n "$piped_input" ] && [ -z "$prompt" ]; then
        prompt="$piped_input"
    fi

    case $mode in
        function)
            generate_function "$fn_name" "$fn_desc" "$provider" "$model"
            ;;
        agent)
            agent_mode "$prompt" "${dry_run:-false}" "$provider" "$model"
            ;;
        chat)
            if [ -n "$prompt" ]; then
                if [ "$context_level" != "none" ]; then
                    local ctx=$(gather_context "$context_level")
                    if [ -n "$ctx" ]; then
                        prompt="Context about my system:\n${ctx}\n\nQuestion: ${prompt}"
                    fi
                fi

                if [ -n "$gh_pr" ]; then
                    local gh_ctx=$(gather_github_context "pr" "$gh_pr")
                    if [ -n "$gh_ctx" ]; then
                        prompt="${gh_ctx}${prompt}"
                    fi
                fi

                if [ -n "$gh_issue" ]; then
                    local gh_ctx=$(gather_github_context "issue" "$gh_issue")
                    if [ -n "$gh_ctx" ]; then
                        prompt="${gh_ctx}${prompt}"
                    fi
                fi

                call_api "$provider" "$model" "$prompt" "$stream" "$system_prompt" "$temperature" "$max_tokens"
                echo ""
            else
                interactive_mode "$provider" "$model" "$stream" "$context_level"
            fi
            ;;
    esac
}

main "$@"
