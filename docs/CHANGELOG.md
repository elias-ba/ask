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

## [0.5.0] - 2026-02-16

### Added

- **Ollama provider support (local LLMs)**
  - `-L, --local` shortcut for `--provider ollama`
  - Dynamic model listing with sizes (`ask -L --list-models`)
  - Streaming and non-streaming support
  - Custom host via `OLLAMA_HOST` env var
  - Skips API key check, verifies server reachability instead

- **Structured output formats for pipeline composability**
  - `-j, --json` — validated JSON wrapped in metadata envelope (model, provider)
  - `-c, --csv` — CSV with headers, markdown code fences stripped
  - `--md, --markdown` — clean Markdown formatting
  - `-r, --raw` — plain text with ANSI codes stripped
  - JSON/CSV automatically disable streaming for post-processing

- **Provider suggestion on missing API key**
  - Detects configured providers and suggests the right command
  - Shows `Try: ask -p <provider>` when alternative keys are available

- **Uninstall instructions** in README

- **DeepSeek provider support**
  - Models: deepseek-chat, deepseek-coder, deepseek-reasoner
  - Key management: `ask keys set deepseek`

### Changed

- Version set to 0.5.0 (semver: pre-1.0, project is evolving)

## [0.4.0] - 2025-09-30

### Added

- **Google Gemini provider support**
  - Models: gemini-3-pro-preview, gemini-2.5-pro, gemini-2.5-flash, gemini-2.5-flash-lite
  - Free tier available at https://aistudio.google.com/apikey
  - Full streaming support with SSE parsing
  - Key management: `ask keys set google`

- **GitHub integration commands**
  - `/gh-pr` — load PR context
  - `/gh-pr-diff` — load PR diff
  - `/gh-issue` — load issue context
  - `/gh-prs`, `/gh-issues` — list PRs and issues
  - `/gh-repo` — show repository info

- **Windows support (PowerShell 7+)**
  - `ask.ps1` — full PowerShell port
  - Contributed by MilkCoder26

## [0.3.0] - 2025-01-15

### Added

- Initial public release
- Multi-provider support (Anthropic, OpenAI, OpenRouter)
- Streaming responses with real-time output
- Agent mode with risk-based command execution
- Three-tier risk assessment (low, medium, high)
- Auto-approve option for safe commands
- Dry-run mode for agent execution plans
- Function generation and management
- Interactive chat mode with conversation history
- Context awareness (none, min, auto, full levels)
- Git integration (commit message generation, PR review)
- Built-in API key management with secure storage
- Custom system prompts (`--system` flag)
- Temperature control (`-t` flag)
- Multi-line input support (`--multiline` flag)
- Conversation save/load functionality
- Interactive commands (/clear, /save, /load, /switch, /models, etc.)
- Bash 3.x+ compatibility
- XDG Base Directory specification compliance
- Piped input support

## Version Numbering

ask follows [Semantic Versioning](https://semver.org/):

- **Major (X.0.0)**: Breaking changes, incompatible API changes
- **Minor (0.X.0)**: New features, backwards compatible
- **Patch (0.0.X)**: Bug fixes, backwards compatible

## Links

- **Repository**: https://github.com/elias-ba/ask
- **Issues**: https://github.com/elias-ba/ask/issues
- **Discussions**: https://github.com/elias-ba/ask/discussions

---

don't grep. don't awk. just ask
