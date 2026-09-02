# ts-academy-devops-assignment-1

A small collection of Bash scripts for inspecting system state:

- [system-info.sh](system-info.sh) — displays host, OS, CPU, memory, and other system details.
- [disk-check.sh](disk-check.sh) — checks disk usage against a threshold.
- [network-check.sh](network-check.sh) — checks DNS resolution, connectivity, interfaces, and optionally a TCP port.

All scripts write timestamped log entries to `logs/`.

## Installation / Setup

Requires Bash and standard Unix tools (`df`, `ping`, `ifconfig`/`ip`, and optionally `dig`/`host`/`getent`). No other dependencies.

```bash
git clone <repo-url>
cd ts-academy-devops-assignment-1
chmod +x system-info.sh disk-check.sh network-check.sh
```

## Usage

### system-info.sh

```bash
./system-info.sh
```

Prints hostname, current user, date/time, OS, kernel version, uptime, CPU info, memory info, and current working directory.

### disk-check.sh

```bash
./disk-check.sh <threshold> [path]
```

- `threshold`: integer from 1 to 100 (required).
- `path`: filesystem path to check (default: `/`).

Prints disk usage percentage for the given path.

Exit codes:
- `0` — usage is below the threshold.
- `1` — usage has reached or exceeded the threshold.
- `2` — invalid input (bad threshold, missing/invalid path, wrong number of args).

Example:

```bash
./disk-check.sh 90 /var
```

### network-check.sh

```bash
./network-check.sh <hostname-or-ip> [port]
```

- `hostname-or-ip`: required.
- `port`: optional, integer from 1 to 65535. If supplied, performs a TCP connectivity check on that port.

Displays DNS resolution, a ping connectivity check, local network interface information, and (if a port is given) TCP port reachability.

Exit codes:
- `0` — host reachable (and port open, if checked).
- `1` — host unreachable, DNS resolution failed, or port closed/unreachable.
- `2` — invalid input (bad host or port, wrong number of args).

Example:

```bash
./network-check.sh example.com 443
```

## Logging

Each script appends timestamped entries to its own log file under `logs/`:

- `logs/system-info.log`
- `logs/disk-check.log`
- `logs/network-check.log`

Log files are created automatically on first run and are git-ignored (`logs/*.log`); only `logs/.gitkeep` is tracked so the directory itself is preserved in the repo.

## Testing

No automated test suite is included. Scripts were manually verified by running them with valid and invalid arguments and checking output, exit codes, and log entries, e.g.:

```bash
./disk-check.sh 90            # valid, exits 0
./disk-check.sh 1             # forces exit 1 (usage >= threshold)
./disk-check.sh 0             # invalid threshold, exits 2
./disk-check.sh 90 /no/such/path   # invalid path, exits 2

./network-check.sh google.com
./network-check.sh google.com 443
./network-check.sh "bad host!"     # invalid host, exits 2
./network-check.sh localhost 99999 # invalid port, exits 2
```

## Assumptions

- Scripts are run on macOS or Linux with a POSIX-compliant shell environment; `bash` is available at `/usr/bin/env bash`.
- `timeout`/`gtimeout` may not be present (notably on stock macOS); `network-check.sh` falls back to a background-process-based timeout for the TCP port check.
- `disk-check.sh` uses `df -P` output format (percentage in the 5th column of the second line), which is standard on both macOS and Linux.
- Hostnames/IPs are validated with a permissive character-class check (letters, digits, dots, hyphens); it does not fully validate IPv6 syntax.
- Network checks depend on outbound connectivity (ping/DNS/TCP); results reflect the environment the script runs in, including any firewalls or restricted egress.
- Log files are treated as local, runtime-generated artifacts and are not committed to version control.
