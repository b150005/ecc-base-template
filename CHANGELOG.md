# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Removed

- `.devcontainer/` scaffold. Forks adopting VS Code Dev Containers
  should author their own `devcontainer.json` against a chosen base
  image — the previous file was fully commented out and added nothing
  beyond what a one-line README mention conveys.

### Fixed

- Stale hook reference removed from the default `.claude/settings.json`
  on `main`. Sessions no longer attempt to resolve a non-existent
  `coaching-context.sh` on first prompt.
