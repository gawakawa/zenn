# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a Zenn content repository for managing articles and books published on [Zenn.dev](https://zenn.dev). Zenn is a Japanese technical publishing platform. The repository uses Nix flakes for development environment management.

## Development Environment

This project uses Nix flakes with direnv for automatic environment setup:
- `flake.nix` defines the development shell with `zenn-cli` package
- `.envrc` automatically loads the Nix environment when entering the directory
- Run `direnv allow` if the environment doesn't load automatically

## Common Commands

### Content Management
- `zenn preview` - Start local preview server to view articles/books in browser
- `zenn new:article` - Create a new article
- `zenn new:book` - Create a new book
- `zenn list:articles` - List all articles
- `zenn list:books` - List all books

### Content Structure
- `articles/` - Contains Zenn article markdown files
- `books/` - Contains Zenn book directories (each book has multiple chapters)

## Architecture

This is a content-only repository with no build process. The Zenn CLI handles:
- Content preview with live reload
- Markdown validation and formatting
- Content metadata management (frontmatter)

Articles and books are written in Markdown with Zenn-specific frontmatter conventions. Refer to the [official Zenn CLI guide](https://zenn.dev/zenn/articles/zenn-cli-guide) for content format specifications.
