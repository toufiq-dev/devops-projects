# DevOps Practice Projects

Hands-on projects I'm building to practice DevOps fundamentals — scripting, packaging, CI/CD, and the Linux internals underneath them.

[![CI](https://github.com/toufiq-dev/devops-projects/actions/workflows/ci.yml/badge.svg)](https://github.com/toufiq-dev/devops-projects/actions/workflows/ci.yml)

## Projects

| # | Project | What it does | Stack |
|---|---------|--------------|-------|
| 01 | [Server Performance Stats](./01-server-stats/) | Bash script reporting CPU, memory, disk, top processes, and system info from `/proc` + standard tools | Bash, `awk`, `/proc`, `free`, `df`, `ps` |

<!-- Add a new row to this table for each new project folder -->

## How this repo is organized

- **One numbered folder per project** (`01-server-stats/`, `02-…/`), each self-contained with its own README (what it does, how to run it, sample output).
- Small scripts live here together; when a project grows real infrastructure of its own (Docker, Terraform, multi-service pipelines), it gets **promoted to its own repository**.
- **CI on every push** ([`ci.yml`](./.github/workflows/ci.yml)): ShellCheck lints every `.sh` file, and a smoke-test job runs the scripts in a clean Debian 12 container — so "works on my machine" is verified, not assumed.

## Why a monorepo?

Practice-scale projects are small. Separate repos per script would bury my GitHub profile in stubs, while a numbered collection shows progression in one place and keeps one clean commit history. Bigger projects graduate out when they outgrow a folder.
