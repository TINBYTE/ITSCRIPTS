# ITSCRIPTS

A collection of Bash scripts for IT managers to streamline day-to-day administration tasks.

## Directory Structure

```
ITSCRIPTS/
├── system/        # System monitoring and health scripts
├── network/       # Network diagnostics and utilities
├── users/         # User account management scripts
├── backup/        # Backup and rotation scripts
├── logs/          # Log analysis and maintenance scripts
└── sagex3/
    ├── scripts/   # Helpful Bash scripts for Sage X3 administration
    └── skills/    # Sage X3 ERP training syllabi and skill references
```

## Requirements

- Bash 4.0+
- Standard Unix utilities (`awk`, `sed`, `grep`, `find`, `df`, `netstat`/`ss`, etc.)
- Some scripts may require `sudo` / root privileges — see individual script headers

## Usage

Make a script executable and run it:

```bash
chmod +x system/system_health.sh
./system/system_health.sh
```

All scripts support a `-h` / `--help` flag that prints usage information.

## Scripts

### system/

| Script | Description |
|--------|-------------|
| `disk_usage.sh` | Report disk usage per mount point with configurable warning thresholds |
| `system_health.sh` | Full system health snapshot (CPU, memory, load, uptime, disk) |
| `service_monitor.sh` | Check whether a list of services is running and restart if needed |

### network/

| Script | Description |
|--------|-------------|
| `ping_sweep.sh` | Ping every host in a CIDR range and list which ones respond |
| `port_scan.sh` | Lightweight TCP port scanner for a single host |
| `network_info.sh` | Display all network interfaces, IPs, routes, and DNS servers |

### users/

| Script | Description |
|--------|-------------|
| `user_audit.sh` | List all local users with their last-login date and account status |
| `bulk_create_users.sh` | Create multiple users from a CSV file |

### backup/

| Script | Description |
|--------|-------------|
| `backup.sh` | Archive a directory with timestamped tar.gz and configurable retention |

### logs/

| Script | Description |
|--------|-------------|
| `log_analyzer.sh` | Summarise error/warning counts in a log file |
| `log_cleaner.sh` | Delete or compress log files older than N days |

### sagex3/scripts/

| Script | Description |
|--------|-------------|
| `x3_service_check.sh` | Check whether core Sage X3 services are running; optionally restart them |
| `x3_log_analyzer.sh` | Scan X3 log/trace files for errors and warnings with per-file summaries |
| `x3_backup.sh` | Create a timestamped archive of an X3 dossier directory with retention |

### sagex3/skills/

Training syllabi and skill references for Sage X3 ERP and related technologies (developer formation, GraphQL API, Power Platform).

## License

MIT