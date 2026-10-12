# f2ban-bans

[![ShellCheck](https://github.com/mradeka/f2ban-bans/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/mradeka/f2ban-bans/actions/workflows/shellcheck.yml)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE.md)
[![Shell: Bash](https://img.shields.io/badge/shell-bash-4EAA25?logo=gnubash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Platform: Linux](https://img.shields.io/badge/platform-linux-informational?logo=linux&logoColor=white)](#requirements)
[![Last commit](https://img.shields.io/github/last-commit/mradeka/f2ban-bans)](https://github.com/mradeka/f2ban-bans/commits/main)
[![Issues](https://img.shields.io/github/issues/mradeka/f2ban-bans)](https://github.com/mradeka/f2ban-bans/issues)

> 🇩🇪 Deutsche Version: [README.de.md](README.de.md)

A Bash script to list, filter, and unban banned IPs across all fail2ban
jails at once - including Bash tab completion for jail names.

## Table of contents

- [Package contents](#package-contents)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [How it works / features](#how-it-works--features)
- [Troubleshooting](#troubleshooting)
- [Uninstall](#uninstall)
- [Changelog](#changelog)
- [License](#license)

## Package contents

| File                         | Purpose                                               |
|------------------------------|-------------------------------------------------------|
| `f2ban-bans`                 | The script itself (goes into `/usr/local/sbin/`)      |
| `f2ban-bans-completion.bash` | Bash completion (goes into `/etc/bash_completion.d/`) |
| `README.md`                  | This documentation (English)                          |
| `README.de.md`               | German documentation                                  |
| `CHANGELOG.md`               | Version history                                       |
| `LICENSE.md`                 | GNU General Public License v3.0                       |

## Requirements

- Linux with `bash` (4.0 or newer; the completion uses `mapfile`)
- `fail2ban` installed, with `fail2ban-client` on `$PATH`
- root privileges (`fail2ban-client` requires it)
- optional: the `bash-completion` package, for automatic tab completion

## Installation

### 0. Get the code

```bash
git clone https://github.com/mradeka/f2ban-bans.git
cd f2ban-bans
```

### 1. Install the main script

```bash
sudo install -o root -g root -m 750 f2ban-bans /usr/local/sbin/f2ban-bans
```

`/usr/local/sbin` is normally on root's `$PATH`, so afterwards the script
can simply be called as `f2ban-bans` from anywhere.

### 2. Install tab completion (optional, but recommended)

```bash
sudo install -o root -g root -m 644 f2ban-bans-completion.bash /etc/bash_completion.d/f2ban-bans
source /etc/bash_completion.d/f2ban-bans   # for the current session
```

New shells will load it automatically, provided the `bash-completion`
package is installed:

```bash
# Debian/Ubuntu
apt install bash-completion

# RHEL/CentOS/SUSE
dnf install bash-completion    # or: zypper install bash-completion
```

**Important:** make sure you actually place `f2ban-bans-completion.bash`
(not the main script `f2ban-bans`) at this path. See
[Troubleshooting](#troubleshooting) for what happens if you mix them up.

### 3. Verify the installation

```bash
f2ban-bans -l
complete -p f2ban-bans
```

The second line should print `complete -F _f2ban_bans_completion
f2ban-bans` (not `_minimal`).

## Usage

```
Usage: f2ban-bans [-p pattern] [-j jail] [-c] [-l] [-u IP] [-h]

  -p PATTERN   Filter banned IPs by regex, e.g. '^92\.' or '92.*'
  -j JAIL      Only show/use this jail instead of all jails
  -c           Show only the number of banned IPs per jail
  -l           Only list active jails, then exit
  -u IP        Unban this IP (all jails, or only -j jail)
  -h           Show this help
```

### Examples

```bash
# All banned IPs, grouped by jail
f2ban-bans

# List active jails (e.g. to pick one for -j)
f2ban-bans -l

# Filter by pattern - a prefix is enough
f2ban-bans -p 92.

# Shell-style pattern is auto-converted to regex
f2ban-bans -p '92.*'

# A full regex works too
f2ban-bans -p '^92\.(1[0-9]|2[0-5])\.'

# Show only a specific jail
f2ban-bans -j sshd

# Combine jail + pattern
f2ban-bans -j sshd -p 92.

# Show only the count per jail (plus a grand total)
f2ban-bans -c

# Unban an IP from every jail it's currently banned in
f2ban-bans -u 92.1.2.3

# Unban an IP from a specific jail only
f2ban-bans -u 92.1.2.3 -j sshd
```

### Example output

```
=== sshd (3) ===
92.9.1.1
92.10.1.1
92.118.39.77
```

Note the numeric ordering: `92.9.x` sorts before `92.10.x`.

### Tab completion

Once the completion file is installed:

```bash
f2ban-bans -j <TAB><TAB>
```

lists the currently active jail names to choose from.

## How it works / features

- **Aggregation across all jails**: queries `fail2ban-client status` to
  get the list of jails, then `fail2ban-client status <jail>` per jail
  for the banned IPs.
- **Sorting & deduplication**: output is sorted numerically by IP octet
  (`92.9.x` before `92.10.x`) and duplicate entries are removed.
  Sorting is octet-based, so it targets IPv4 addresses.
- **Colored output**: only enabled when stdout is a terminal (no ANSI
  escape-code clutter when redirected to a file or piped).
- **Pattern filtering**: `-p` accepts POSIX extended regular
  expressions. A simple shell-style pattern ending in `*` (e.g. `92.*`)
  is automatically converted into a matching regex (`^92\.`).
- **Root required**: the script exits with a clear message if it isn't
  run as root.
- **Source guard**: the script detects if it's accidentally `source`d
  instead of executed directly, and aborts cleanly instead of letting
  `set -euo pipefail` leak into the calling shell (see Troubleshooting).

## Troubleshooting

### Tab completion shows file/directory names instead of jail names

Cause: `/etc/bash_completion.d/f2ban-bans` doesn't contain the
completion file but accidentally the main script (e.g. mixed up during
copying).

Check:
```bash
head -5 /etc/bash_completion.d/f2ban-bans
```
If it shows `# f2ban-bans - list, filter, and unban...` instead of
`# Bash completion for f2ban-bans`, the wrong file is in place.

Fix:
```bash
sudo install -o root -g root -m 644 f2ban-bans-completion.bash /etc/bash_completion.d/f2ban-bans
source /etc/bash_completion.d/f2ban-bans
```

### SSH session dies with "unbound variable" (e.g. `LC_BYOBU`)

Cause: same as above. If the main script (with `set -euo pipefail`) gets
sourced automatically instead of the completion file, `set -u` stays
active permanently in that interactive shell. The next time the shell
(or something like byobu) references an unset variable, `set -e` +
`set -u` terminate the shell - and with it the SSH session.

Fix: see above. As of the current script version there's an additional
safeguard: a `BASH_SOURCE[0]` vs. `$0` check that makes the script abort
immediately with an error message if it's ever sourced, instead of
affecting the shell - a second line of defense against exactly this
issue.

### `fail2ban-client` not found

```bash
which fail2ban-client
```
If empty: fail2ban isn't installed, or the relevant path is missing
from root's `$PATH`.

### "This script must be run as root"

Call it with `sudo f2ban-bans ...`, or log in as root.

## Uninstall

```bash
sudo rm -f /usr/local/sbin/f2ban-bans
sudo rm -f /etc/bash_completion.d/f2ban-bans
```

## Changelog

See [CHANGELOG.md](CHANGELOG.md).

## Contributing

Issues and pull requests are welcome. Please run
[ShellCheck](https://www.shellcheck.net/) on both scripts before opening a
pull request - the same check runs automatically in CI:

```bash
shellcheck f2ban-bans
shellcheck -s bash f2ban-bans-completion.bash
```

## License

This project is licensed under the **GNU General Public License v3.0** -
see [LICENSE.md](LICENSE.md) for details.
