# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2026-10-13

First versioned release.

### Added
- Status query across all fail2ban jails with regex filtering (`-p`).
- `-j` jail filter and `-c` count mode.
- `-l` to list active jails.
- `-u` to unban an IP directly, across all jails or a specific one.
- Numeric sorting and deduplication of the IP output.
- Colored terminal output (only when stdout is a terminal).
- Bash tab completion for jail names.
- Source guard against accidentally sourcing the script into an interactive
  shell (prevents `set -u` from killing the SSH session).
- Badges and table of contents in the README.
- ShellCheck workflow (GitHub Actions) for both scripts.
- This changelog.

### Changed
- Whole project translated to English (script messages, comments, documentation).
  The German documentation is kept as `README.de.md`.
- Completion now uses `mapfile` instead of unquoted command substitution
  (ShellCheck SC2207).
