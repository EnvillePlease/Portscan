#!/usr/bin/env python3
# -----------------------------------------------------------------------------
# Application: get-openports
# Description: Concurrent TCP port scanner using asynchronous socket connection attempts.
# Author: Clark Nelson
# Company: Capita Plc
# Version: 1.0.0
# -----------------------------------------------------------------------------
"""Concurrent TCP port scanner.

Example:
    python get-openports.py -t example.com -s 1 -e 1024 --timeout 200 --concurrency 200
"""

from __future__ import annotations

import argparse
import asyncio
import socket
import sys

MIN_PORT = 1
MAX_PORT = 65535

def _validate_scan_settings(
    start_port: int,
    end_port: int,
    timeout_ms: int,
    concurrency: int
    ) -> None:
    """Validate scan inputs and raise ValueError for invalid ranges or limits."""
    if not MIN_PORT <= start_port <= MAX_PORT:
        raise ValueError(f"Start port must be between {MIN_PORT} and {MAX_PORT}.")
    if not MIN_PORT <= end_port <= MAX_PORT:
        raise ValueError(f"End port must be between {MIN_PORT} and {MAX_PORT}.")
    if start_port > end_port:
        raise ValueError("Start port must be less than or equal to end port.")
    if timeout_ms < 1:
        raise ValueError("Timeout must be greater than 0 milliseconds.")
    if concurrency < 1:
        raise ValueError("Concurrency must be greater than 0.")

def _probe_port(target: str, port: int, timeout_seconds: float) -> bool:
    """Try a single TCP connect and return True if the port accepts the connection."""
    try:
        with socket.create_connection((target, port), timeout=timeout_seconds):
            return True
    except (OSError, socket.timeout):
        return False

async def scan_port(target: str, port: int, timeout_ms: int) -> tuple[int, bool]:
    """Check one port and return the port number with its open/closed state."""
    timeout_seconds = max(timeout_ms / 1000.0, 0.001)
    try:
        is_open = await asyncio.to_thread(_probe_port, target, port, timeout_seconds)
    except Exception:
        return port, False
    return port, is_open

async def scan_ports(
    target: str,
    start_port: int,
    end_port: int,
    timeout_ms: int,
    concurrency: int,
) -> list[int]:
    """Scan a port range concurrently and return the ports that accepted a TCP connection."""
    semaphore = asyncio.Semaphore(max(1, concurrency))

    async def worker(port: int) -> tuple[int, bool]:
        """Limit each connection attempt to the configured concurrency level."""
        async with semaphore:
            return await scan_port(target, port, timeout_ms)

    tasks = [asyncio.create_task(worker(port)) for port in range(start_port, end_port + 1)]
    try:
        results = await asyncio.gather(*tasks)
    finally:
        for task in tasks:
            if not task.done():
                task.cancel()

    return [port for port, is_open in results if is_open]

def parse_args() -> argparse.Namespace:
    """Parse the CLI options and return the validated settings used for the scan."""
    parser = argparse.ArgumentParser(
        description="Scan a range of TCP ports on a target host and list the open ones.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument(
        "-t",
        "--target",
        required=True,
        help="DNS name or IP address to scan."
        )
    parser.add_argument(
        "-s",
        "--start-port",
        type=int,
        default=MIN_PORT,
        help="Starting port number."
        )
    parser.add_argument(
        "-e",
        "--end-port",
        type=int,
        default=MAX_PORT,
        help="Ending port number."
        )
    parser.add_argument(
        "--timeout",
        type=int,
        default=200,
        help="Timeout in milliseconds per port check."
        )
    parser.add_argument(
        "--concurrency",
        type=int,
        default=200,
        help="Maximum number of concurrent connection attempts.",
    )
    return parser.parse_args()

async def main_async() -> int:
    """Validate settings, run the scan, and print any open ports found."""
    args = parse_args()
    _validate_scan_settings(args.start_port, args.end_port, args.timeout, args.concurrency)

    open_ports = await scan_ports(
        target=args.target,
        start_port=args.start_port,
        end_port=args.end_port,
        timeout_ms=args.timeout,
        concurrency=args.concurrency,
    )

    if not open_ports:
        print(
            f"No open ports found on {args.target} between {args.start_port} and {args.end_port}."
            )
        return 0

    print(f"Open ports on {args.target} ({args.start_port}-{args.end_port}):")
    for port in open_ports:
        print(f"  {port}")
    return 0

def main() -> int:
    """CLI entry point that converts user errors into concise stderr output."""
    try:
        return asyncio.run(main_async())
    except ValueError as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 1
    except KeyboardInterrupt:
        print("\nScan aborted.")
        return 130

if __name__ == "__main__":
    raise SystemExit(main())
