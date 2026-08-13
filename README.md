# TCP Port Scanner

A concurrent TCP port scanner for PowerShell that quickly identifies open ports on a target host.

## What it does

`get-openports.ps1` scans a range of TCP ports on a target host using asynchronous connection attempts. It runs multiple scans in parallel for speed and returns a list of open ports.

**Requirements:** PowerShell 7+

## Usage

```powershell
pwsh -File .\get-openports.ps1 -Target <host> [-StartPort <int>] [-EndPort <int>] [-Timeout <ms>] [-ThrottleLimit <int>]
```

## Parameters

- **-Target** (required): DNS name or IP address to scan
- **-StartPort** (default: 1): First port to check
- **-EndPort** (default: 65535): Last port to check
- **-Timeout** (default: 200): Milliseconds to wait per connection attempt
- **-ThrottleLimit** (default: 200): Maximum parallel scan threads

## Examples

Scan common ports on example.com:
```powershell
pwsh -File .\get-openports.ps1 -Target example.com -StartPort 1 -EndPort 1024
```

Scan ports 8000-8100 on localhost with a 500ms timeout:
```powershell
pwsh -File .\get-openports.ps1 -Target localhost -StartPort 8000 -EndPort 8100 -Timeout 500
```

Show help:
```powershell
pwsh -File .\get-openports.ps1 -Help
```

## Output

Returns a list of open ports with their status.
