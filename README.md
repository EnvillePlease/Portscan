# Portscan

A small concurrent TCP port scanner available in both PowerShell and Python.

## PowerShell

```powershell
pwsh -File .\get-openports.ps1 -Target <host> [-StartPort <int>] [-EndPort <int>] [-Timeout <ms>] [-ThrottleLimit <int>]
```

Parameters:
- `-Target` (required): DNS name or IP address to scan
- `-StartPort` (default: 1): first port to check
- `-EndPort` (default: 65535): last port to check
- `-Timeout` (default: 200): milliseconds per connection attempt
- `-ThrottleLimit` (default: 200): maximum parallel tasks

Example:
```powershell
pwsh -File .\get-openports.ps1 -Target example.com -StartPort 1 -EndPort 1024 -Timeout 200 -ThrottleLimit 200
```

## Python

```bash
python3 get-openports.py -t <host> [-s <int>] [-e <int>] [--timeout <ms>] [--concurrency <int>]
```

Parameters:
- `-t, --target` (required): DNS name or IP address to scan
- `-s, --start-port` (default: 1): first port to check
- `-e, --end-port` (default: 65535): last port to check
- `--timeout` (default: 200): milliseconds per connection attempt
- `--concurrency` (default: 200): maximum concurrent checks

Example:
```bash
python3 get-openports.py -t example.com -s 1 -e 1024 --timeout 200 --concurrency 200
```

## Notes

- Both versions scan TCP ports and print the ports that accept a connection.
- Python requires Python 3.12 and uses only the standard library.
- The script is intended for targeted scans rather than full-range reconnaissance on large networks.
