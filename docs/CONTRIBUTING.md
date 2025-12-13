# Contributing to ask

Thanks for your interest in contributing to ask! This guide will help you get started.

## How to Contribute

### Reporting Bugs

Found a bug? Please open an issue with:

- **Clear description** of the problem
- **Steps to reproduce** the issue
- **Expected vs actual behavior**
- **Environment details**: OS, bash version, provider used
- **Error messages** (if any)

Example:

```bash
Title: Agent mode fails with empty plan

Description: When using agent mode with certain prompts,
the tool fails to generate a valid execution plan.

Steps to reproduce:
1. Run: ask --agent "simple task"
2. Tool shows error: "Failed to generate valid execution plan"

Environment:
- OS: macOS 14.0
- Bash: 5.2.15
- Provider: anthropic
- Model: claude-sonnet-4-5-20250929

Error output:
[paste error here]
```

### Suggesting Features

Have an idea? Open an issue with:

- **Use case**: What problem does this solve?
- **Proposed solution**: How should it work?
- **Alternatives considered**: Other approaches you thought about
- **Examples**: Show how users would use this feature

### Code Contributions

#### Development Setup

1. **Fork the repository**

   ```bash
   # On GitHub, click "Fork"
   ```

2. **Clone your fork**

   ```bash
   git clone https://github.com/yourusername/ask.git
   cd ask
   ```

3. **Create a branch**

   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/your-bug-fix
   ```

4. **Make your changes**

   ```bash
   vim ask  # Edit the main script
   ```

5. **Test thoroughly**

   ```bash
   # Test basic functionality
   ./ask "test query"

   # Test your specific change
   ./ask --your-new-flag "test"

   # Test edge cases
   ./ask --your-new-flag ""
   ./ask --your-new-flag "special characters: @#$%"
   ```

6. **Commit your changes**

   ```bash
   git add ask
   git commit -m "feat: add new feature"
   # or
   git commit -m "fix: resolve issue with agent mode"
   ```

7. **Push and create PR**

   ```bash
   git push origin feature/your-feature-name
   # Then open a Pull Request on GitHub
   ```

## Code Style Guidelines

### Bash Style

Follow these conventions:

```bash
# Use lowercase for local variables
local my_variable="value"

# Use UPPERCASE for constants
readonly MAX_RETRIES=3

# Quote variables to prevent word splitting
echo "$my_variable"

# Use [[ ]] for conditionals (bash specific)
if [[ "$value" = "expected" ]]; then
    # do something
fi

# Function names use snake_case
my_function() {
    local param=$1
    # implementation
}

# Add comments for complex logic
# This function handles streaming API responses
# by parsing SSE format and extracting content
handle_stream() {
    # implementation
}
```

### Code Organization

- **Keep functions focused**: One function, one responsibility
- **Handle errors**: Check return codes, validate input
- **Avoid globals when possible**: Use local variables in functions
- **Document complex logic**: Add comments explaining "why", not "what"

### Compatibility

- **Maintain Bash 3.x compatibility**: Don't use Bash 4+ features
- **Test on multiple platforms**: macOS (Bash 3.x) and Linux (Bash 4+)
- **Avoid GNU-specific tools**: Use POSIX-compatible alternatives when possible

```bash
# Bad - Bash 4+ only
declare -A my_array

# Good - Bash 3.x compatible
case $key in
    option1) value="val1" ;;
    option2) value="val2" ;;
esac
```

## Testing

### Manual Testing Checklist

Before submitting a PR, test:

- [ ] Basic queries: `ask "test"`
- [ ] Piped input: `echo "test" | ask "summarize"`
- [ ] Agent mode: `ask --agent --dry-run "test task"`
- [ ] Function generation: `ask --fn test_fn "description"`
- [ ] Interactive mode: `ask` then try various commands
- [ ] Key management: `ask keys list`
- [ ] Different providers: `-p anthropic`, `-p openai`, `-p google`
- [ ] Context levels: `--context none/min/auto/full`
- [ ] Error handling: Invalid flags, missing API keys

### Validation Tools

```bash
# Check syntax
bash -n ask

# Use shellcheck (if available)
shellcheck ask

# Test installation
./install.sh
```

## Pull Request Guidelines

### PR Title Format

Use conventional commits format:

- `feat: add new feature`
- `fix: resolve bug in agent mode`
- `docs: update examples`
- `refactor: simplify API call logic`
- `test: add tests for streaming`
- `chore: update dependencies`

### PR Description Template

```markdown
## Description

Brief description of changes

## Type of Change

- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Refactoring
- [ ] Other (please describe)

## Testing Done

- [ ] Tested on macOS
- [ ] Tested on Linux
- [ ] Tested all providers
- [ ] Tested edge cases

## Related Issues

Fixes #123
Related to #456

## Screenshots (if applicable)

[paste terminal output or screenshots]
```

## Documentation

### When to Update Docs

Update documentation when you:

- Add a new feature → Update README.md, EXAMPLES.md
- Add a flag → Update help text in `show_help()`
- Change behavior → Update CHANGELOG.md
- Add examples → Add to EXAMPLES.md

### Documentation Style

- **Be concise**: Get to the point quickly
- **Use examples**: Show, don't just tell
- **Test examples**: Ensure all examples actually work
- **Update help text**: Keep `ask --help` in sync with features

## Project Structure

```bash
ask/
├── ask              # Main executable (this is what you edit)
├── install.sh       # Installation script
├── README.md        # Main documentation
├── docs/
│   ├── QUICKSTART.md
│   ├── EXAMPLES.md
│   ├── KEYS.md
│   ├── CONTRIBUTING.md (this file)
│   └── CHANGELOG.md
└── examples/        # Example scripts
```

## Feature Development Workflow

### Adding a New Flag

1. **Update argument parsing** in `main()`

   ```bash
   --your-flag)
       your_variable="$2"
       shift 2
       ;;
   ```

2. **Update help text** in `show_help()`

   ```bash
   $(echo -e "${GREEN}--your-flag${NC}") VALUE    Description
   ```

3. **Implement functionality**

   ```bash
   handle_your_flag() {
       # implementation
   }
   ```

4. **Add examples** to EXAMPLES.md

5. **Update CHANGELOG.md**

### Adding a New Provider

1. **Add to `get_models()`**

   ```bash
   newprovider) echo "model1,model2,model3" ;;
   ```

2. **Add to `get_api_url()`**

   ```bash
   newprovider) echo "https://api.newprovider.com/endpoint" ;;
   ```

3. **Add to `call_api()`** - implement API calling logic

4. **Add to `manage_keys()`** - support key management

5. **Test thoroughly** with the new provider

6. **Update documentation**

## Community

### Getting Help

- **GitHub Discussions**: For questions and general discussion
- **GitHub Issues**: For bugs and feature requests
- **Pull Requests**: For code contributions

### Code of Conduct

- **Be respectful**: Treat others with kindness
- **Be constructive**: Provide helpful feedback
- **Be patient**: Remember everyone is learning
- **Be inclusive**: Welcome all contributors

## Recognition

Contributors will be:

- Listed in CHANGELOG.md for their contributions
- Mentioned in release notes
- Added to a CONTRIBUTORS.md file (if created)

## Questions?

Not sure about something? Open an issue or discussion - we're happy to help!

---

don't grep. don't awk. just ask (and contribute!)
