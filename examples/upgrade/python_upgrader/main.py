# main.py

import argparse
import time
import json
import os
import re
from remote_executor import run_remote_script, run_remote_script_via_proxy

# Helper functions


def slp(duration):
    time.sleep(duration)


def str_to_bool(arg):
    # Convert string "true" or "false" to Python boolean value
    return arg.lower() == "true"


# Get the absolute path to a script file in the same directory as this
def get_script_file_path(script_file_name):
    script_dir = get_current_directory()
    return os.path.join(script_dir, script_file_name)


# Get the absolute path of the currently executing script
def get_current_directory():
    return os.path.dirname(os.path.abspath(__file__))


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


def run_remote_script_maybe_with_proxy(agentless_gw, script_contents, script_run_command):
    if agentless_gw.get("proxy") is not None:
        script_output = run_remote_script_via_proxy(agentless_gw.get("ip"),
                                                    agentless_gw.get("ssh_user"),
                                                    agentless_gw.get("ssh_private_key_file_path"),
                                                    script_contents,
                                                    script_run_command,
                                                    agentless_gw.get("proxy").get("ip"),
                                                    agentless_gw.get("proxy").get("ssh_user"),
                                                    agentless_gw.get("proxy").get("ssh_private_key_file_path"))
    else:
        script_output = run_remote_script(agentless_gw.get("ip"),
                                          agentless_gw.get("ssh_user"),
                                          agentless_gw.get("ssh_private_key_file_path"),
                                          script_contents,
                                          script_run_command)
    return script_output

# Main functions


def main():
    args = parse_args()
    agentless_gws = json.loads(args.agentless_gws)
    hubs = json.loads(args.dsf_hubs)

    print("********** Inputs ************")

    print_inputs(agentless_gws, hubs, args)

    print("********** Start ************")

    preflight_validations_passed = True
    if args.run_preflight_validations:
        preflight_validations_passed = run_all_preflight_validations(agentless_gws, hubs, args.target_version)

    if preflight_validations_passed:
        print(f"### Preflight validations passed")
    else:
        print(f"Aborting upgrade...")
        return

    upgrade_succeeded = True
    if preflight_validations_passed and args.run_upgrade:
        upgrade_succeeded = run_upgrade(agentless_gws, args.target_version)

    if upgrade_succeeded and args.run_postflight_validations:
        run_postflight_validations()

    print("********** End ************")


def parse_args():
    parser = argparse.ArgumentParser(description="Upgrade script for DSF Hub and Agentless Gateway")
    parser.add_argument("--agentless_gws", help="JSON-encoded Agentless Gateway list")
    parser.add_argument("--dsf_hubs", help="JSON-encoded DSF Hub list")
    parser.add_argument("--target_version", required=True, help="Target version to upgrade")
    parser.add_argument("--run_preflight_validations", type=str_to_bool, help="Whether to run preflight validations")
    parser.add_argument("--run_postflight_validations", type=str_to_bool, help="Whether to run postflight validations")
    parser.add_argument("--custom_validations_scripts", help="List of custom validation scripts")
    parser.add_argument("--run_upgrade", type=str_to_bool, help="Whether to run the upgrade")
    args = parser.parse_args()
    return args


def print_inputs(agentless_gws, hubs, args):
    print("List of Agentless Gateways:")
    print_dsf_nodes(agentless_gws)
    print("List of DSF Hubs:")
    print_dsf_nodes(hubs)
    print(f"target_version: {args.target_version}")
    print(f"run_preflight_validations: {args.run_preflight_validations}")
    print(f"run_postflight_validations: {args.run_postflight_validations}")
    print(f"custom_validations_scripts: {args.custom_validations_scripts}")
    print(f"run_upgrade: {args.run_upgrade}")


def print_dsf_nodes(dsf_nodes):
    print("---")
    for item in dsf_nodes:
        print(f"IP: {item.get('ip')}")
        print(f"SSH User: {item.get('ssh_user')}")
        print(f"SSH Key: {item.get('ssh_private_key_file_path')}")
        print(f"Proxy: {item.get('proxy')}")
        print("---")


def run_all_preflight_validations(agentless_gws, hubs, target_version):
    print("----- Preflight validations")

    preflight_validations_passed, ip = run_preflight_validations_for_dsf_nodes(agentless_gws, target_version,
                                                                               "run_preflight_validations.py")
    if not preflight_validations_passed:
        print(f"### Preflight validations didn't pass for Agentless Gateway {ip}")
        return False
    preflight_validations_passed, ip = run_preflight_validations_for_dsf_nodes(hubs, target_version,
                                                                               "run_preflight_validations.py")
    if not preflight_validations_passed:
        print(f"### Preflight validations didn't pass for DSF Hub {ip}")
        return False
    return True


def run_preflight_validations_for_dsf_nodes(dsf_nodes, target_version, script_file_name):
    for dsf_node in dsf_nodes:
        preflight_validations_result = run_preflight_validations(dsf_node, target_version, script_file_name)
        if not are_preflight_validations_passed(preflight_validations_result):
            return False, dsf_node.get('ip')
    return True, None


def run_preflight_validations(dsf_node, target_version, script_file_name):
    print(f"Running preflight validations for DSF node {dsf_node.get('ip')}")
    python_location = run_get_python_location_script(dsf_node)
    print(f"Python location in DSF node {dsf_node.get('ip')} is {python_location}")

    preflight_validations_result_json = run_preflight_validations_script(dsf_node, target_version, python_location,
                                                                         script_file_name)
    preflight_validations_result = json.loads(preflight_validations_result_json)
    print(f"Preflight validations result in DSF node {dsf_node.get('ip')} is {preflight_validations_result}")
    return preflight_validations_result


def run_get_python_location_script(dsf_node):
    script_file_path = get_script_file_path("get_python_location.sh")
    script_contents = read_file_contents(script_file_path)
    script_run_command = build_bash_script_run_command(script_contents)

    script_output = run_remote_script_maybe_with_proxy(dsf_node, script_contents, script_run_command)

    print(f"'Get python location' bash script output: {script_output}")
    return extract_python_location(script_output)


def extract_python_location(script_output):
    pattern = r'Python location: (\S+)'
    match = re.search(pattern, script_output)

    if match:
        return match.group(1)
    else:
        raise Exception("Pattern 'Python location: ...' not found in 'Get python location' script output")


def run_preflight_validations_script(dsf_node, target_version, python_location, script_file_name):
    script_file_path = get_script_file_path(script_file_name)
    script_contents = read_file_contents(script_file_path)
    script_run_command = build_python_script_run_command(script_contents, target_version, python_location)
    # print(f"script_run_command: {script_run_command}")

    script_output = run_remote_script_maybe_with_proxy(dsf_node, script_contents, script_run_command)
    print(f"'Run preflight validations' python script output: {script_output}")
    return extract_preflight_validations_result(script_output)


def extract_preflight_validations_result(script_output):
    pattern = r'Preflight validations result: ({.+})'
    match = re.search(pattern, script_output)

    if match:
        return match.group(1)
    else:
        raise Exception("Pattern 'Preflight validations result: ...' not found in 'Run preflight validations' "
                        "script output")


def are_preflight_validations_passed(preflight_validations_result):
    return not preflight_validations_result.get('same_version') \
           and preflight_validations_result.get('min_version') \
           and preflight_validations_result.get('max_version_hop')


def run_upgrade(agentless_gws, target_version):
    print("----- upgrade Agentless Gateway DR")
    return upgrade_gw(agentless_gws[0], "DR", target_version)
    # print("----- upgrade gw Main")
    # upgrade_gw("Main", args.target_version)


def upgrade_gw(agentless_gw, gw_type, target_version):
    print(f"----- upgrade gw {agentless_gw} of type {gw_type}")
    print("take backup of the gateway")
    slp(short_sleep_seconds)
    print(f"----- upgrade gateway {gw_type}")
    slp(short_sleep_seconds)
    print("run upgrade script")
    result = run_upgrade_script(agentless_gw, target_version)
    if result:
        print(f"Upgrading gateway {agentless_gw} was ### successful ###")
    else:
        print(f"Upgrading gateway {agentless_gw} ### failed ### ")
    return result


def run_upgrade_script(agentless_gw, target_version):
    if run_dummy_upgrade:
        script_file_name = 'dummy_upgrade_script.sh'
    else:
        script_file_name = 'upgrade_v4_10.sh'
    script_file_path = get_script_file_path(script_file_name)
    script_contents = read_file_contents(script_file_path)

    args = "1ef8de27-ed95-40ff-8c08-7969fc1b7901 jsonar-4.12.0.10.0.tar.gz us-east-1"
    script_run_command = build_bash_script_run_command(script_contents, args)
    # print(f"script_run_command: {script_run_command}")

    script_output = run_remote_script_maybe_with_proxy(agentless_gw, script_contents, script_run_command)

    print(f"Upgrade bash script output: {script_output}")
    # This relies on the fact that Sonar outputs the string "Upgrade completed"
    return "Upgrade completed" in script_output


def run_postflight_validations():
    print("----- Postflight validations")
    # TODO
    print("check the version of the gateway")
    print("version: 4.12")


if __name__ == "__main__":
    short_sleep_seconds = 0  # 3
    long_sleep_seconds = 0  # 5
    very_long_sleep_seconds = 0  # 10
    run_dummy_upgrade = False

    main()
