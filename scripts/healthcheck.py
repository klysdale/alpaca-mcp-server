import os
import socket
import sys


def check_tcp(host: str, port: int, timeout: float = 2.0) -> bool:
    try:
        with socket.create_connection((host, port), timeout=timeout):
            return True
    except OSError:
        return False


def main() -> int:
    port = int(os.environ.get("PORT", "7800"))
    # Prefer a configurable loopback target over the bind host (0.0.0.0 is not connectable).
    host = os.environ.get("MCP_HEALTH_HOST", "127.0.0.1")

    if check_tcp(host, port):
        return 0

    # Fall back to the declared host when different from loopback.
    bind_host = os.environ.get("HOST", "0.0.0.0")
    if bind_host != host and check_tcp(bind_host, port):
        return 0

    return 1


if __name__ == "__main__":
    sys.exit(main())
