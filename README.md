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
    └── skills/    # Sage X3 ERP skills and administration scripts
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

### sagex3/skills/

Scripts for Sage X3 ERP skills and administration tasks will be added here.

## License

MIT