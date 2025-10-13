# Zenn CLI

Repository for managing articles and books on Zenn.dev.

## Directory Structure

```
.
├── articles/      # Article markdown files
├── books/         # Book directories
├── flake.nix      # Nix development environment
└── .envrc         # direnv configuration
```

## Commands

```bash
# Preview
zenn preview

# Create new content
zenn new:article
zenn new:book

# List content
zenn list:articles
zenn list:books
```

## Documentation

* [📘 How to use](https://zenn.dev/zenn/articles/zenn-cli-guide)