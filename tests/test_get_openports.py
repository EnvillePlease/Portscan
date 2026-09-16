# test_get_openports.py
import json
import subprocess
import sys
import os
import pytest

# Path to the two scripts
# Absolute path to the Python scanner located in the parent directory
PY_SCRIPT = os.path.abspath(
    os.path.join(os.path.dirname(__file__), '..', 'get-openports.py')
)

# Absolute path to the PowerShell scanner located in the parent directory
PS_SCRIPT = os.path.abspath(
    os.path.join(os.path.dirname(__file__), '..', 'get-openports.ps1')
)

@pytest.mark.parametrize("host,start,end,timeout,concurrency,expected", [
    ("127.0.0.1", 22, 22, 200, 10, [22]),
    ("127.0.0.1", 80, 80, 200, 10, []),
    ("127.0.0.1", 1, 1024, 200, 20, [22]),
    ("127.0.0.1", 1, 65535, 200, 100, [22]),
    ("example.com", 80, 80, 200, 5, [80]),
    ("example.com", 443, 443, 200, 5, [443]),
    ("example.com", 1, 1024, 200, 10, [80, 443]),
])
def test_port_scan_consistency(host, start, end, timeout, concurrency, expected):
    # Build command lines that output JSON
    py_cmd = [
        sys.executable, PY_SCRIPT,
        '--target', host,
        '--start-port', str(start),
        '--end-port', str(end),
        '--timeout', str(timeout),
        '--concurrency', str(concurrency),
        '--json'          # flag that makes the script print JSON
    ]

    ps_cmd = [
        'pwsh', '-NoLogo', '-NoProfile', '-Command',
        f"Set-Location {os.path.dirname(PS_SCRIPT)}; .\\{os.path.basename(PS_SCRIPT)}",
        '-Target', host,
        '-StartPort', str(start),
        '-EndPort', str(end),
        '-Timeout', str(timeout),
        '-ThrottleLimit', str(concurrency),
        '-Json'         # custom switch that tells the PS script to output JSON
    ]

    # Run both scripts
    py_out = subprocess.check_output(py_cmd, text=True)
    ps_out = subprocess.check_output(ps_cmd, text=True)

    py_ports = json.loads(py_out.strip())
    ps_ports = json.loads(ps_out.strip())

    # Compare the two lists irrespective of order
    assert sorted(py_ports) == sorted(ps_ports) == sorted(expected)