#region Script Header
<#
 .SCRIPTNAME
    get-openports.ps1

 .AUTHOR
    Clark Nelson

 .COMPANY
    Capita Plc

 .VERSION
    1.0.0

 .SYNOPSIS
    Concurrent TCP port scanner using ConnectAsync.

 .DESCRIPTION
    Scans a range of TCP ports on a target host using asynchronous connects.
    Uses `ForEach-Object -Parallel` (PowerShell 7+) and `System.Net.Sockets.TcpClient.ConnectAsync`.

 .PARAMETER Target
    DNS name or IP address of the host to scan.

 .PARAMETER StartPort
    The starting port number (inclusive).

 .PARAMETER EndPort
    The ending port number (inclusive).

 .PARAMETER Timeout
    Timeout in milliseconds for each connection attempt. A connection not
    established within this interval is treated as closed/unreachable.

 .PARAMETER ThrottleLimit
    Maximum concurrent tasks used by `ForEach-Object -Parallel`.

 .EXAMPLE
    pwsh -File .\get-openports.ps1 -Target example.com -StartPort 1 -EndPort 1024 -Timeout 200 -ThrottleLimit 200

 .OUTPUTS
    PSCustomObject with `Port` and `Status` properties for open ports.

 .NOTES
    - Designed for interactive use and small-to-medium ranges. For full 1..65535 scans
      consider spreading across multiple runs or using a dedicated scanner.
    - Errors from failed connects are intentionally suppressed to keep output concise.
#>
#endregion Script Header


param (
   [Parameter(Position = 0)]
   [string]$Target,

   [Parameter()]
   [ValidateRange(1, 65535)]
   [int]$StartPort = 1,

   [Parameter()]
   [ValidateRange(1, 65535)]
   [int]$EndPort = 65535,

   [Parameter()]
   [ValidateRange(1, 10000)]
   [int]$Timeout = 200,

   [Parameter()]
   [ValidateRange(1, 1000)]
   [int]$ThrottleLimit = 200,

   [Alias('h')]
   [Parameter()]
   [switch]$Help
)

# Show a concise usage/help screen for developers and operators. This is shown
# when the user passes -Help/-h or omits the required `-Target` parameter.
function Show-Help {
   param([string]$Message)

   if ($Message) {
      Write-Host "ERROR: $Message`n" -ForegroundColor Yellow
   }

   $exe = if ($MyInvocation.MyCommand.Path) { $MyInvocation.MyCommand.Path } else { 'get-openports.ps1' }

   Write-Host "Usage: pwsh -File $exe -Target <host> [-StartPort <int>] [-EndPort <int>] [-Timeout <ms>] [-ThrottleLimit <int>] [-Help]" -ForegroundColor Cyan
   Write-Host ""
   Write-Host "Parameters:"
   Write-Host "  -Target       DNS name or IP address of the host to scan (required unless -Help)."
   Write-Host "  -StartPort    Starting port number (default: 1)."
   Write-Host "  -EndPort      Ending port number (default: 65535)."
   Write-Host "  -Timeout      Timeout in milliseconds per connection attempt (default: 200)."
   Write-Host "  -ThrottleLimit Max concurrent tasks for parallel scan (default: 200)."
   Write-Host "  -Help, -h     Show this help message."
   Write-Host "" 
   Write-Host "Example: pwsh -File $exe -Target example.com -StartPort 1 -EndPort 1024 -Timeout 200 -ThrottleLimit 200"
}

# If user asked for help or didn't supply a target, show help and exit.
if ($Help -or -not $Target) {
   if (-not $Help -and -not $Target) {
      Show-Help "Missing required parameter: -Target"
   }
   else {
      Show-Help
   }
   return
}

# Validate logical parameter relationships before scanning.
if ($StartPort -gt $EndPort) {
   Show-Help "StartPort must be less than or equal to EndPort"
   return
}

# Create the requested port range. Note: large ranges (1..65535) may consume
# many resources even with throttling — choose sensible Start/End values.
$ports = $StartPort..$EndPort

# ForEach-Object -Parallel runs the scriptblock in parallel runspaces. We
# reference the parent-scope parameters via $using: to capture their values.

# Attempt parallel scan using ForEach-Object -Parallel. If the cmdlet's
# parameter binding fails in this environment, fall back to a sequential loop.
try {
   $ports | ForEach-Object -Parallel {
      $port = $_
      $target = $using:Target
      $timeout = $using:Timeout

      $tcp = [System.Net.Sockets.TcpClient]::new()
      try {
         $connectTask = $tcp.ConnectAsync($target, $port)
         if ($connectTask.Wait($timeout)) {
            if ($tcp.Connected) {
               [PSCustomObject]@{
                  Port = $port
                  Status = 'Open'
               }
            }
         }
      }
      catch {
         # suppressed
      }
      finally {
         $tcp.Dispose()
      }

   } -ThrottleLimit $ThrottleLimit
}
catch {
   # Common fallback for environments where -Parallel is unsupported or
   # parameter binding fails. Sequential scan is slower but robust.
   Write-Host "Parallel execution unavailable; falling back to sequential scan." -ForegroundColor Yellow

   foreach ($port in $ports) {
      $tcp = [System.Net.Sockets.TcpClient]::new()
      try {
         $task = $tcp.ConnectAsync($Target, $port)
         if ($task.Wait($Timeout)) {
            if ($tcp.Connected) {
               [PSCustomObject]@{
                  Port = $port
                  Status = 'Open'
               }
            }
         }
      }
      catch {
         # suppressed
      }
      finally {
         $tcp.Dispose()
      }
   }
}