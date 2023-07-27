# main.py

import argparse
import time
import json


def slp(duration=10):
    time.sleep(duration)


def run_upgrade_script(gw_json, target_version):
    # TODO ssh to gw_json.ip via gw_json.proxy.ip if available and run upgrade_v4_10.sh script
    return


def upgrade_gw(gw_json, gw_type, target_version):
    print(f"----- upgrade gw {gw_json} of type {gw_type}")
    print("take backup of the gateway")
    slp(3)
    print(f"----- upgrade gateway {gw_type}")
    slp(3)
    print("run upgrade script")
    run_upgrade_script(gw_json, target_version)
    print("----- run post upgrade script")
    slp(3)
    print(f"----- move traffic to {gw_type}")
    slp(3)


def print_gw(target_agentless_gws_json):
    for item in target_agentless_gws_json:
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
    parser = argparse.ArgumentParser(description="Upgrade script for DSF Hub and Agentless Gateway")
    parser.add_argument("--target_version", required=True, help="Target version to upgrade")
    parser.add_argument("--target_agentless_gws", required=True, help="JSON-encoded Agentless Gateway list")
    parser.add_argument("--target_hubs", required=True, help="JSON-encoded DSF Hub list")
    parser.add_argument("--run_preflight_validations", type=str_to_bool, help="Run preflight validations")
    parser.add_argument("--run_postflight_validations", type=str_to_bool, help="Run postflight validations")
    parser.add_argument("--custom_validations_scripts", required=True, help="List of custom validation scripts")

    args = parser.parse_args()
    target_agentless_gws_json = json.loads(args.target_agentless_gws)

    print("********** Reading Inputs ************")
    slp(5)
    print("gw list:")
    print_gw(target_agentless_gws_json)
    print("hub list: []")
    print(f"target_version {args.target_version}")
    print(f"run_preflight_validations {args.run_preflight_validations}")
    print(f"run_postflight_validations {args.run_postflight_validations}")
    print(f"custom_validations_scripts {args.custom_validations_scripts}")

    print("********** Start ************")
    slp(5)
    print("----- Pre-flight validations")
    print("check the version of the gateway")
    print("version: 4.11")
    # print("check the version of the hub")
    # print("version: 4.11")
    print(f"compare the version of the gateway and hub and target version: {args.target_version}")
    print("check disk space")
    slp()
    print("----- Custom validations")
    print(f"run: {args.custom_validations_scripts}")
    slp()
    print("----- upgrade Agentless Gateway DR")
    upgrade_gw(target_agentless_gws_json[0], "DR", args.target_version)
    # print("----- upgrade gw Main")
    # upgrade_gw("Main", args.target_version)

    print("----- Post-flight validations")
    print("check the version of the gateway")
    print("version: 4.12")

    print("********** End ************")

if __name__ == "__main__":
    main()
