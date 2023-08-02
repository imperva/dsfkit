# main.py

import argparse
import time
import json
import os
from remote_executor import run_remote_script, run_remote_script_via_proxy


def slp(duration):
    time.sleep(duration)


def read_bash_script(file_path):
    try:
        with open(file_path, 'r') as file:
            script_content = file.read()
        return script_content
    except FileNotFoundError:
        print(f"File not found: {file_path}")
        return None


def replace_script_args(script_contents, script_args):
    return script_contents.replace("$1", script_args[0])\
        .replace("$2", script_args[1])\
        .replace("$3", script_args[2])


def run_upgrade_script(gw_json, target_version):
    # Get the absolute path of the currently executing script
    script_dir = os.path.dirname(os.path.abspath(__file__))
    # Construct the absolute path to the bash script file
    if run_dummy_upgrade:
        script_file_path = os.path.join(script_dir, 'dummy_upgrade_script.sh')
    else:
        script_file_path = os.path.join(script_dir, 'upgrade_v4_10.sh')

    script_contents = read_bash_script(script_file_path)
    if script_contents is None:
        return False
    script_args = ["1ef8de27-ed95-40ff-8c08-7969fc1b7901", "jsonar-4.12.0.10.0.tar.gz", "us-east-1"]
    script_contents_with_args = replace_script_args(script_contents, script_args)

    if "proxy" in gw_json:
        script_output = run_remote_script_via_proxy(gw_json.get("ip"),
                                                    gw_json.get("ssh_user"),
                                                    gw_json.get("ssh_private_key_file_path"),
                                                    script_contents_with_args,
                                                    gw_json.get("proxy").get("ip"),
                                                    gw_json.get("proxy").get("ssh_user"),
                                                    gw_json.get("proxy").get("ssh_private_key_file_path"))
    else:
        script_output = run_remote_script(gw_json.get("ip"),
                                          gw_json.get("ssh_user"),
                                          gw_json.get("ssh_private_key_file_path"),
                                          script_contents_with_args)

    print(f"Bash script output ################ : {script_output}")
    return True


def upgrade_gw(gw_json, gw_type, target_version):
    print(f"----- upgrade gw {gw_json} of type {gw_type}")
    print("take backup of the gateway")
    slp(short_sleep_seconds)
    print(f"----- upgrade gateway {gw_type}")
    slp(short_sleep_seconds)
    print("run upgrade script")
    result = run_upgrade_script(gw_json, target_version)
    if result:
        print(f"Upgrading gateway {gw_json} was successful")
        print("----- run post upgrade script")
        slp(short_sleep_seconds)
        print(f"----- move traffic to {gw_type}")
        slp(short_sleep_seconds)
    else:
        print(f"Upgrading gateway {gw_json} failed")


def print_gw(target_agentless_gws_json):
    for item in target_agentless_gws_json:
        # Extract values from the JSON
        ip = item.get("ip")
        ssh_user = item.get("ssh_user")
        ssh_key = item.get("ssh_private_key_file_path")
        proxy = item.get("proxy")

        # Use the extracted values
        print(f"IP: {ip}")
        print(f"SSH User: {ssh_user}")
        print(f"SSH Key: {ssh_key}")
        print(f"Proxy: {proxy}")
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
    slp(long_sleep_seconds)
    print("gw list:")
    print_gw(target_agentless_gws_json)
    print("hub list: []")
    print(f"target_version {args.target_version}")
    print(f"run_preflight_validations {args.run_preflight_validations}")
    print(f"run_postflight_validations {args.run_postflight_validations}")
    print(f"custom_validations_scripts {args.custom_validations_scripts}")

    print("********** Start ************")
    slp(long_sleep_seconds)
    print("----- Pre-flight validations")
    print("check the version of the gateway")
    print("version: 4.11")
    # print("check the version of the hub")
    # print("version: 4.11")
    print(f"compare the version of the gateway and hub and target version: {args.target_version}")
    print("check disk space")
    slp(very_long_sleep_seconds)
    print("----- Custom validations")
    print(f"run: {args.custom_validations_scripts}")
    slp(very_long_sleep_seconds)
    print("----- upgrade Agentless Gateway DR")
    upgrade_gw(target_agentless_gws_json[0], "DR", args.target_version)
    # print("----- upgrade gw Main")
    # upgrade_gw("Main", args.target_version)

    print("----- Post-flight validations")
    print("check the version of the gateway")
    print("version: 4.12")

    print("********** End ************")


if __name__ == "__main__":
    short_sleep_seconds = 0  # 3
    long_sleep_seconds = 0  # 5
    very_long_sleep_seconds = 0  # 10
    run_dummy_upgrade = False

    main()
