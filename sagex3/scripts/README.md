# sagex3/scripts

Helpful Bash scripts for Sage X3 ERP administration and operations.

## Scripts

| Script | Description |
|--------|-------------|
| [`x3_service_check.sh`](x3_service_check.sh) | Check whether the core Sage X3 services (`adxd`, `adxadmin`, `SageX3WebServer`) are running; optionally restart stopped services |
| [`x3_log_analyzer.sh`](x3_log_analyzer.sh) | Scan one or all X3 log/trace files for errors and warnings; prints per-file summaries with the most-recent matching lines |
| [`x3_backup.sh`](x3_backup.sh) | Create a timestamped `tar.gz` archive of an X3 dossier directory with configurable retention policy |

## Requirements

- Bash 4.0+
- Standard Unix utilities: `tar`, `find`, `grep`, `tail`, `wc`, `du`, `ps`/`pgrep`
- `systemctl` recommended for service management (SysV `service` used as fallback)
- Some operations require `sudo` / root privileges — see each script header

## Usage

```bash
# Make scripts executable
chmod +x sagex3/scripts/*.sh

# Check all X3 services
./x3_service_check.sh

# Check and restart stopped services (requires root)
sudo ./x3_service_check.sh -r

# Analyze last 2000 lines of all logs under /opt/sagex3/log
./x3_log_analyzer.sh -n 2000

# Analyze a specific log file
./x3_log_analyzer.sh -l /opt/sagex3/log/adxd.log

# Back up a dossier to /var/backups/sagex3 and keep 30 days of archives
./x3_backup.sh -k 30 /opt/sagex3/folders/MYCOMP

# Back up to a custom destination
./x3_backup.sh -d /mnt/nas/x3backups -k 14 /opt/sagex3/folders/MYCOMP
```

All scripts support a `-h` / `--help` flag that prints full usage information.
