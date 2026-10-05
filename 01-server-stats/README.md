# 01 — Server Performance Stats

A bash script that answers the question *"how is this server doing right now?"* by reading the `/proc` filesystem and standard Unix tools — no monitoring agent, no dependencies to install.

Back to the [project index](../README.md).

## What it reports

| Section | Source | Why it matters |
|---|---|---|
| Total CPU usage | `/proc/stat` (two samples, delta) | Same technique `top` uses — counters are cumulative, so a rate needs two reads |
| Memory usage | `free -m` | `available` is the honest number; `used` includes cache |
| Disk usage | `df -h` | Excludes virtual filesystems (`tmpfs`, `devtmpfs`) that always look full |
| Top 5 processes by CPU | `ps --sort=-%cpu` | Finds runaway processes |
| Top 5 processes by memory | `ps --sort=-%mem` | Finds leaks |
| System info | `/etc/os-release`, `uname`, `uptime`, `who`, auth logs | Quick context: what, where, how long, who's on it |

## Requirements

- Linux with GNU coreutils and `procps` (`free`, `ps`, `uptime`)
- No root required (the failed-login section falls back gracefully if logs aren't readable)
- **Not** macOS/BSD — it depends on `/proc` and GNU-only flags like `df --output` and `ps --sort`
- No Linux box handy? CI runs this script on a clean Debian 12 container on every push (see [`ci.yml`](../.github/workflows/ci.yml)), or try it locally:

  ```bash
  docker run --rm -v "$PWD/server-stats.sh:/tmp/server-stats.sh:ro" debian:12 bash /tmp/server-stats.sh
  ```

## Usage

```bash
chmod +x server-stats.sh
./server-stats.sh
```

## Sample output

```text
Server Performance Stats — Sun Oct  5 14:32:01 UTC 2026

==============================================
  Total CPU Usage
==============================================
CPU Usage: 6.12%
Idle:      93.88%

==============================================
  Total Memory Usage (RAM)
==============================================
Total:      7982 MB
Used:       2103 MB (26.35%)
Free:       3019 MB
Available:  5483 MB

Swap Total: 2047 MB
Swap Used:  0 MB (0.00%)

==============================================
  Total Disk Usage
==============================================
Filesystem      Size  Used Avail Use% Mounted on
/dev/vda1        40G   11G   27G  29% /
```

<!-- TODO: replace the block above with real output from your own machine (or the CI run) -->

## What I learned

- `/proc` is a live window into the kernel — cumulative counters mean *rates* require two samples and a delta
- `awk` column extraction (`/^Mem:/ {print $7}`) — the workhorse of DevOps scripting
- Defensive bash: `set -euo pipefail`, quoting variables, handling missing data (a system can have no Swap line)
- Reading Linux's memory numbers correctly: high `used` with high `available` is just page cache, not a problem

## Stretch goals

- [ ] Network throughput from `/proc/net/dev`
- [ ] Inode usage (`df -i`) — the "disk looks full but isn't" failure mode
- [ ] Top 5 directories by size
- [ ] Zombie process count
- [ ] Colour output (ANSI codes)
- [ ] `--cpu`, `--mem`, `--disk` flags to run single sections
- [ ] `--json` output for machine parsing
