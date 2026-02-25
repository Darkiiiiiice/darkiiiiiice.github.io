# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a personal Hugo blog using the Hugo NexT theme, deployed to GitHub Pages. The site supports both Markdown and AsciiDoc content formats.

## Common Commands

```bash
# Start local development server with draft content
hugo server -D

# Build for production
hugo --minify

# Install AsciiDoc dependencies (required for .adoc content)
make depends
```

## Architecture

### Directory Structure
- `config.yaml` - Main Hugo configuration (theme settings, menus, params)
- `content/` - Blog content organized by section
  - `posts/` - Blog posts organized in subdirectories by date (e.g., `202407/`)
  - `about.md` - About page
  - `archives/` - Archives page content
- `themes/next/` - Hugo NexT theme (git submodule from hugo-next/hugo-theme-next)
- `layouts/` - Custom layout overrides
  - `partials/comments.html` - Custom comments partial
- `static/` - Static assets (images, etc.)
- `public/` - Generated site output (gitignored)

### Theme Configuration
The site uses Hugo NexT theme (v4.8.3). Key configurations in `config.yaml`:
- Scheme: Gemini
- Dark mode enabled
- Local search enabled
- Math rendering: KaTeX
- Code block style: Mac

### Content Format
Posts can be written in Markdown (.md) or AsciiDoc (.adoc). AsciiDoc requires the dependencies installed via `make depends`.

### Deployment
Automatically deployed to GitHub Pages via `.github/workflows/hugo.yml` on push to main branch. The workflow:
1. Installs Hugo extended version
2. Initializes git submodules for theme
3. Installs AsciiDoc dependencies
4. Builds and deploys to GitHub Pages

## Theme Submodule Notes

The theme is a git submodule. If `themes/next/` is empty, initialize it:
```bash
git submodule update --init --recursive
# or
git clone https://github.com/hugo-next/hugo-theme-next.git themes/next
```
