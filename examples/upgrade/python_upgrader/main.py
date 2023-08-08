# main.py

import argparse
import time
import json
import os
import re
from remote_executor import run_remote_script, run_remote_script_via_proxy


def slp(duration):
    time.sleep(duration)


# Get the absolute path of the currently executing script
def get_current_directory():
    return os.path.dirname(os.path.abspath(__file__))


# Get the absolute path to a script file in the same directory as this
def get_script_file_path(script_file_name):
    script_dir = get_current_directory()
    return os.path.join(script_dir, script_file_name)


def read_file_contents(file_path):
    try:
        with open(file_path, "r") as file:
            script_content = file.read()
        return script_content
    except FileNotFoundError:
        raise Exception(f"File not found: {file_path}")
    except Exception:
        raise Exception(f"Failed to read contents of file: {file_path}")


def build_bash_script_run_command(script_contents, args=""):
    return f"sudo bash -c '{script_contents}' {args}"


def build_python_script_run_command(script_contents, args, python_location):
    return f"sudo {python_location} -c '{script_contents}' {args}"


def run_remote_script_maybe_with_proxy(gw_json, script_contents, script_run_command):
    if gw_json.get("proxy") is not None:
        script_output = run_remote_script_via_proxy(gw_json.get("ip"),
                                                    gw_json.get("ssh_user"),
                                                    gw_json.get("ssh_private_key_file_path"),
                                                    script_contents,
                                                    script_run_command,
                                                    gw_json.get("proxy").get("ip"),
                                                    gw_json.get("proxy").get("ssh_user"),
                                                    gw_json.get("proxy").get("ssh_private_key_file_path"))
    else:
        script_output = run_remote_script(gw_json.get("ip"),
                                          gw_json.get("ssh_user"),
                                          gw_json.get("ssh_private_key_file_path"),
                                          script_contents,
                                          script_run_command)
    return script_output


def extract_python_location(script_output):
    pattern = r'Python location: (\S+)'
    match = re.search(pattern, script_output)

    if match:
        return match.group(1)
    else:
        raise Exception("Pattern 'Python location: ...' not found in 'Get python location' script output")


def run_get_python_location_script(gw_json):
    script_file_path = get_script_file_path("get_python_location.sh")
    script_contents = read_file_contents(script_file_path)
    script_run_command = build_bash_script_run_command(script_contents)

    script_output = run_remote_script_maybe_with_proxy(gw_json, script_contents, script_run_command)

    print(f"'Get python location' bash script output: {script_output}")
    python_location = extract_python_location(script_output)
    print(f"Python location in Agentless Gateway {gw_json.get('ip')} is {python_location}")
    return python_location


def extract_preflight_validations_result(script_output):
    pattern = r'Preflight validations result: ({.+})'
    match = re.search(pattern, script_output)

    if match:
        return match.group(1)
    else:
        raise Exception("Pattern 'Preflight validations result: ...' not found in 'Run preflight validations' "
                        "script output")


def run_preflight_validations_script(gw_json, target_version, python_location):
    script_file_path = get_script_file_path("run_preflight_validations.py")
    script_contents = read_file_contents(script_file_path)
    script_run_command = build_python_script_run_command(script_contents, target_version, python_location)
    # print(f"script_run_command: {script_run_command}")

    script_output = run_remote_script_maybe_with_proxy(gw_json, script_contents, script_run_command)
    print(f"'Run preflight validations' python script output: {script_output}")
    preflight_validations_result = extract_preflight_validations_result(script_output)
    print(f"Preflight validation results in Agentless Gateway {gw_json.get('ip')} are {preflight_validations_result}")
    return preflight_validations_result


def run_preflight_validations(agentless_gws_json, target_version):
    print("----- Preflight validations")
    print("check the version of the gateway")
    python_location = run_get_python_location_script(agentless_gws_json[0])

    preflight_validations_result_json = run_preflight_validations_script(agentless_gws_json[0], target_version,
                                                                         python_location)

    preflight_validations_result = json.loads(preflight_validations_result_json)
    return preflight_validations_result

    # TODO run validations
    # print("version: 4.11")
    # print("check the version of the hub")
    # print("version: 4.11")
    # print(f"compare the version of the gateway and hub and target version: {args.target_version}")
    print("check disk space")
    slp(very_long_sleep_seconds)


def run_upgrade_script(gw_json, target_version):
    if run_dummy_upgrade:
        script_file_name = 'dummy_upgrade_script.sh'
    else:
        script_file_name = 'upgrade_v4_10.sh'
    script_file_path = get_script_file_path(script_file_name)
    script_contents = read_file_contents(script_file_path)

    args = "1ef8de27-ed95-40ff-8c08-7969fc1b7901 jsonar-4.12.0.10.0.tar.gz us-east-1"
    script_run_command = build_bash_script_run_command(script_contents, args)
    # print(f"script_run_command: {script_run_command}")

    script_output = run_remote_script_maybe_with_proxy(gw_json, script_contents, script_run_command)

    print(f"Upgrade bash script output: {script_output}")
    # This relies on the fact that Sonar outputs the string "Upgrade completed"
    return "Upgrade completed" in script_output


def upgrade_gw(gw_json, gw_type, target_version):
    print(f"----- upgrade gw {gw_json} of type {gw_type}")
    print("take backup of the gateway")
    slp(short_sleep_seconds)
    print(f"----- upgrade gateway {gw_type}")
    slp(short_sleep_seconds)
    print("run upgrade script")
    result = run_upgrade_script(gw_json, target_version)
    if result:
        print(f"Upgrading gateway {gw_json} was ### successful ###")
    else:
        print(f"Upgrading gateway {gw_json} ### failed ### ")
    return result


def run_upgrade(agentless_gws_json, target_version):
    print("----- upgrade Agentless Gateway DR")
    return upgrade_gw(agentless_gws_json[0], "DR", target_version)
    # print("----- upgrade gw Main")
    # upgrade_gw("Main", args.target_version)


def print_gw(agentless_gws_json):
    for item in agentless_gws_json:
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


def run_postflight_validations():
    print("----- Postflight validations")
    # TODO
    print("check the version of the gateway")
    print("version: 4.12")


def str_to_bool(arg):
    # Convert string "true" or "false" to Python boolean value
    return arg.lower() == "true"


def main():
    parser = argparse.ArgumentParser(description="Upgrade script for DSF Hub and Agentless Gateway")
    parser.add_argument("--target_version", required=True, help="Target version to upgrade")
    parser.add_argument("--agentless_gws", required=True, help="JSON-encoded Agentless Gateway list")
    parser.add_argument("--dsf_hubs", required=True, help="JSON-encoded DSF Hub list")
    parser.add_argument("--run_preflight_validations", type=str_to_bool, help="Whether to run preflight validations")
    parser.add_argument("--run_postflight_validations", type=str_to_bool, help="Whether to run postflight validations")
    parser.add_argument("--custom_validations_scripts", required=True, help="List of custom validation scripts")
    parser.add_argument("--run_upgrade", type=str_to_bool, help="Whether to run the upgrade")

    args = parser.parse_args()
    # TODO remove json from agentless_gws_json, json.loads converts a json string to an object
    agentless_gws_json = json.loads(args.agentless_gws)

    print("********** Reading Inputs ************")
    slp(long_sleep_seconds)
    print("gw list:")
    print_gw(agentless_gws_json)
    print("hub list: []")
    print(f"target_version {args.target_version}")
    print(f"run_preflight_validations {args.run_preflight_validations}")
    print(f"run_postflight_validations {args.run_postflight_validations}")
    print(f"custom_validations_scripts {args.custom_validations_scripts}")
    print(f"run_upgrade {args.run_upgrade}")

    print("********** Start ************")

    preflight_validations_passed = True
    if args.run_preflight_validations:
        preflight_validations_passed = run_preflight_validations(agentless_gws_json, args.target_version)

    print("----- Custom validations")
    print(f"run: {args.custom_validations_scripts}")

    upgrade_succeeded = True
    if preflight_validations_passed and args.run_upgrade:
        upgrade_succeeded = run_upgrade(agentless_gws_json, args.target_version)

    if upgrade_succeeded and args.run_postflight_validations:
        run_postflight_validations()

    print("********** End ************")


if __name__ == "__main__":
    short_sleep_seconds = 0  # 3
    long_sleep_seconds = 0  # 5
    very_long_sleep_seconds = 0  # 10
    run_dummy_upgrade = False

    main()
