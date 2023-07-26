# main.py

import argparse
import time
import json

def slp(duration=10):
    time.sleep(duration)

def upgrade_gw(gw_type, target_version):
    print(f"----- upgrade gw {gw_type}")
    print("take backup of the gateway")
    slp(3)
    print(f"----- upgrade gateway {gw_type}")
    print(f"download tarball {target_version}")
    slp(3)
    print("run upgrade script")
    print("----- run post upgrade script")
    slp(3)
    print(f"----- move traffic to {gw_type}")
    slp(3)

def print_gw(json_str):
    data = json.loads(json_str)
    for item in data:
        # Extract values from the JSON
        id = item.get("id")
        ssh_key = item.get("ssh_key")

        # Use the extracted values
        print(f"ID: {id}")
        print(f"SSH Key: {ssh_key}")
        print("---")

def str_to_bool(arg):
    # Convert string "true" or "false" to Python boolean value
    return arg.lower() == "true"

def main():
    parser = argparse.ArgumentParser(description="Upgrade script for gateway and hub")
    parser.add_argument("--target_version", required=True, help="Target version to upgrade")
    parser.add_argument("--target_gws_by_id", required=True, help="JSON-encoded gateway list")
    parser.add_argument("--target_hubs_by_id", required=True, help="JSON-encoded hub list")
    parser.add_argument("--run_preflight_validation", type=str_to_bool, help="Run preflight validation")
    parser.add_argument("--run_postflight_validation", type=str_to_bool, help="Run postflight validation")
    parser.add_argument("--custom_validations_scripts", required=True, help="List of custom validation scripts")

    args = parser.parse_args()

    print("********** Reading Inputs ************")
    slp(5)
    print("gw_list:")
    print_gw(args.target_gws_by_id)
    print("hub list:")
    print_gw(args.target_hubs_by_id)
    print(f"target_version {args.target_version}")
    print(f"custom_validations_scripts {args.custom_validations_scripts}")

    print("********** Start ************")
    slp(5)
    print("----- pre-flight check")
    print("check the version of the gateway")
    print("version: 4.9")
    print("check the version of the hub")
    print("version: 4.9")
    print(f"compare the version of the gateway and hub and target version: {args.target_version}")
    print("check disk space")
    slp()
    print("----- custom checks")
    print(f"run: {args.custom_validations_scripts}")
    slp()
    print("----- upgrade gw secondary")
    upgrade_gw("secondary", args.target_version)
    print("----- upgrade gw primary")
    upgrade_gw("primary", args.target_version)
    print("********** End ************")

if __name__ == "__main__":
    main()
