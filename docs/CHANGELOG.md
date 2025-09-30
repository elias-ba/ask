# Changelog

All notable changes to ask will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned

- Shell completion scripts (bash, zsh, fish)
- Project indexing for context-aware queries
- Conversation search functionality
- Export conversations to markdown
- Plugin system for custom tools

## [1.0.0] - 2025-01-XX

### Added

- Initial release of ask
- Multi-provider support (Anthropic, OpenAI, OpenRouter)
- Streaming responses with real-time output
- Agent mode with risk-based command execution
- Three-tier risk assessment (low, medium, high)
- Auto-approve option for safe commands
- Dry-run mode for agent execution plans
- Function generation and management
- Syntax validation for generated functions
- Function editing before save
- Interactive chat mode with conversation history
- Context awareness (none, min, auto, full levels)
- Git integration (commit message generation, PR review)
- Built-in API key management with secure storage
- Key encryption with 600 permissions
- Multiple key management commands (set, list, remove, path)
- Custom system prompts (`--system` flag)
- Temperature control (`-t` flag)
- JSON output mode (`--json` flag)
- Multi-line input support (`--multiline` flag)
- Conversation save/load functionality
- Interactive commands (/clear, /save, /load, /switch, /models, etc.)
- Context level switching in interactive mode
- Model switching in interactive mode
- Bash 3.x+ compatibility
- XDG Base Directory specification compliance
- Piped input support
- Configuration persistence
- Model listing by provider
- Thinking indicator with minimum display time
- Comprehensive error handling
- API key validation on startup

### CLI Features

- Quick one-shot queries: `ask "question"`
- Interactive mode: `ask` (no arguments)
- Agent mode: `ask --agent "task"`
- Function generation: `ask --fn name "description"`
- Git commit helper: `ask commit`
- Provider selection: `-p, --provider`
- Model selection: `-m, --model`
- Temperature control: `-t, --temperature`
- Streaming toggle: `-s, --stream` or `-n, --no-stream`
- Context control: `--context [level]`
- System prompts: `--system "prompt"`
- Dry run: `--dry-run`
- Tool restrictions: `--tools "tool1,tool2"`
- JSON output: `--json`
- Multi-line input: `--multiline`
- List models: `--list-models`
- Version: `-v, --version`
- Help: `-h, --help`

### Key Management

- `ask keys set <provider>` - Set API key with secure prompt
- `ask keys list` - List configured keys (masked)
- `ask keys remove <provider>` - Remove API key
- `ask keys path` - Show keys file location
- Keys stored in `~/.config/ask/keys.env` with 600 permissions
- Support for environment variable fallback
- Environment variable precedence over stored keys

### Interactive Commands

- `/clear` - Clear conversation history
- `/save` - Save conversation to file
- `/load` - Load previous conversation
- `/models` - List available models
- `/switch [provider] [model]` - Switch provider/model
- `/context [level]` - Change context level
- `/help` - Show help
- `/exit` or `/quit` - Exit interactive mode

### Documentation

- Comprehensive README with quick start
- Detailed EXAMPLES.md with real-world use cases
- QUICKSTART.md for 5-minute setup
- KEYS.md for key management guide
- CONTRIBUTING.md for contributors
- Installation script with dependency checking

### Configuration

- Config directory: `~/.config/ask/`
- Cache directory: `~/.cache/ask/`
- Generated functions: `~/.config/ask/functions.sh`
- API keys: `~/.config/ask/keys.env`
- Conversation history: `~/.cache/ask/history.jsonl`
- Context cache: `~/.cache/ask/context.json`

### Dependencies

- bash 3.x or higher
- curl (for API calls)
- jq (for JSON processing)

### Supported Providers

- **Anthropic**: Claude Sonnet 4.5, Claude Opus 4.1, Claude Opus 4
- **OpenAI**: GPT-4o, GPT-4o-mini, GPT-4-turbo, o1, o1-mini
- **OpenRouter**: Multi-model access via unified API

## [0.9.0] - 2024-12-XX (Beta)

### Added

- Initial beta release
- Basic query functionality
- Anthropic provider support
- Simple agent mode
- Function generation prototype

### Changed

- Refined API calling logic
- Improved error messages
- Better streaming implementation

### Fixed

- Streaming buffer issues
- Context gathering edge cases
- Key loading from environment

## Version History

### Version Numbering

ask follows [Semantic Versioning](https://semver.org/):

- **Major (X.0.0)**: Breaking changes, incompatible API changes
- **Minor (0.X.0)**: New features, backwards compatible
- **Patch (0.0.X)**: Bug fixes, backwards compatible

### Release Schedule

- **Major releases**: When breaking changes are necessary
- **Minor releases**: Every 2-3 months with new features
- **Patch releases**: As needed for bug fixes

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for details on how to contribute to ask.

## Links

- **Repository**: https://github.com/elias-ba/ask
- **Issues**: https://github.com/elias-ba/ask/issues
- **Discussions**: https://github.com/elias-ba/ask/discussions

---

**don't grep. don't awk. just ask**
