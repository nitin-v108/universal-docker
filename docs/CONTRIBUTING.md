# Contributing to Docker Laravel Boilerplate

This document describes how to contribute to this project.

---

## How to Contribute

### Reporting Issues

If you find a bug or have a suggestion:

1. Check if the issue already exists
2. Create a new issue with:
   - Clear title
   - Detailed description
   - Steps to reproduce (for bugs)
   - Expected vs actual behavior
   - Environment (Windows version, WSL2 version, Docker version)

### Suggesting Enhancements

1. Open an issue with a label such as "enhancement"
2. Describe the feature and its benefit
3. Include examples if possible

### Submitting Changes

1. **Fork the repository**

2. **Create a feature branch:**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes:**
   - Follow existing patterns
   - Update documentation as needed
   - Test your changes

4. **Commit:**
   ```bash
   git commit -m "Add: brief description of changes"
   ```

   Suggested prefixes:
   - `Add:` – new features
   - `Fix:` – bug fixes
   - `Update:` – updates to existing features
   - `Docs:` – documentation
   - `Refactor:` – refactoring

5. **Push and open a Pull Request**

---

## Development Guidelines

### Docker Configuration

- Validate with `docker compose config`
- Ensure images build and containers start
- Verify all services run correctly

### Scripts

- Make scripts executable: `chmod +x script.sh`
- Add error handling where appropriate
- Document complex logic in comments
- Test in a fresh WSL2 environment

### Documentation

- Keep README.md and docs/ up to date
- Update SETUP.md for installation changes
- Add comments to complex configurations
- Use clear, simple language

### Testing

Before submitting:

```bash
make down
docker system prune -af
make rebuild
make ps
make help
```

---

## Code Style

### Shell Scripts

- Use 2-space indentation
- Shebang: `#!/bin/bash`
- Use `set -e` for error handling where appropriate
- Comment non-obvious operations

### YAML

- 2-space indentation
- Quote strings when needed
- Consistent formatting

### Markdown

- ATX-style headers (`#`, `##`, `###`)
- Table of contents for long docs
- Code blocks with language specified

---

## Questions

Open an issue with the "question" label.
