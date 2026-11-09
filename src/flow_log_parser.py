
import argparse
from collections import defaultdict

# Minimum number of different rejected ports to flag a possible scan
SCAN_THRESHOLD = 5


def analyze_flow_logs(file_path):
    rejected_attempts = defaultdict(int)
    rejected_ports = defaultdict(set)

    with open(file_path, "r", encoding="utf-8") as file:
        for line_number, line in enumerate(file, start=1):
            fields = line.split()

            # Standard VPC Flow Logs format contains 14 fields
            if len(fields) < 14:
                continue

            src_ip = fields[3]
            dst_port = fields[6]
            protocol = fields[7]
            action = fields[12]

            if action != "REJECT":
                continue

            # Only count TCP and UDP connections with valid ports
            if protocol not in ("6", "17") or not dst_port.isdigit():
                continue

            rejected_attempts[src_ip] += 1
            rejected_ports[src_ip].add(int(dst_port))

    print("\n===== REJECTED TRAFFIC ANALYSIS =====")

    if not rejected_attempts:
        print("No rejected TCP/UDP connections found.")
        return

    for ip, count in sorted(
        rejected_attempts.items(),
        key=lambda item: item[1],
        reverse=True
    ):
        ports = sorted(rejected_ports[ip])
        possible_scan = len(ports) >= SCAN_THRESHOLD

        print(f"\nSource IP: {ip}")
        print(f"Rejected attempts: {count}")
        print(f"Unique destination ports: {len(ports)}")
        print(f"Ports: {ports}")
        print(
            "Status: POSSIBLE PORT SCAN"
            if possible_scan
            else "Status: Normal rejected traffic"
        )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Analyze rejected AWS VPC Flow Logs"
    )
    parser.add_argument("file", help="Path to Flow Log sample file")
    args = parser.parse_args()

    analyze_flow_logs(args.file)
