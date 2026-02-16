# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 0.5.x   | Yes                |
| < 0.5   | No                 |

## Reporting a Vulnerability

If you discover a security vulnerability in `ask`, please report it responsibly.

**Do not open a public issue.**

Instead, email **eliaswalyba@gmail.com** with:

- A description of the vulnerability
- Steps to reproduce
- Potential impact

You should receive a response within 48 hours. We will work with you to understand and address the issue before any public disclosure.

## Security Considerations

`ask` handles API keys and executes shell commands. Key security measures:

- API keys are stored in `~/.config/ask/keys.env` with `600` permissions (owner-only read/write)
- Agent mode uses a three-tier risk assessment before executing commands
- High-risk commands always require explicit user confirmation
- No data is sent to third parties beyond the configured LLM provider
- Ollama mode (`-L`) keeps all data local
