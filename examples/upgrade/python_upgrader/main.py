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
    python_location_dict = {}
    if args.run_preflight_validations:
        preflight_validations_passed, python_location_dict = run_all_preflight_validations(agentless_gws, hubs,
                                                                                           args.target_version)

    if preflight_validations_passed:
        print(f"### Preflight validations passed")
    else:
        print(f"Aborting upgrade...")
        return

    if preflight_validations_passed:
        success = maybe_upgrade_and_postflight(agentless_gws, hubs, args.target_version, args.run_upgrade,
                                               args.run_postflight_validations, python_location_dict)
        print_upgrade_result = args.run_upgrade
        print_postflight_result = not args.run_upgrade and args.run_postflight_validations
        if print_upgrade_result:
            if success:
                print(f"### Upgrade succeeded")
            else:
                print(f"### Upgrade failed")
        if print_postflight_result:
            if success:
                print(f"### Upgrade postflight validations passed")
            else:
                print(f"### Upgrade postflight validations didn't pass")

    print("********** End ************")


def parse_args():
    parser = argparse.ArgumentParser(description="Upgrade script for DSF Hub and Agentless Gateway")
    parser.add_argument("--agentless_gws", help="JSON-encoded Agentless Gateway list")
    parser.add_argument("--dsf_hubs", help="JSON-encoded DSF Hub list")
    parser.add_argument("--target_version", required=True, help="Target version to upgrade")
    parser.add_argument("--run_preflight_validations", required=True, type=str_to_bool, help="Whether to run preflight validations")
    parser.add_argument("--run_postflight_validations", required=True, type=str_to_bool, help="Whether to run postflight validations")
    parser.add_argument("--custom_validations_scripts", help="List of custom validation scripts")
    parser.add_argument("--run_upgrade", required=True, type=str_to_bool, help="Whether to run the upgrade")
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

    python_location_dict = {}
    preflight_validations_passed = run_preflight_validations_for_dsf_nodes(agentless_gws, "Agentless Gateway",
                                                                           target_version,
                                                                           "run_preflight_validations.py",
                                                                           python_location_dict)
    if not preflight_validations_passed:
        return False, python_location_dict
    preflight_validations_passed = run_preflight_validations_for_dsf_nodes(hubs, "DSF Hub", target_version,
                                                                           "run_preflight_validations.py",
                                                                           python_location_dict)
    return preflight_validations_passed, python_location_dict


def run_preflight_validations_for_dsf_nodes(dsf_nodes, dsf_node_type, target_version, script_file_name,
                                            python_location_dict):
    for dsf_node in dsf_nodes:
        preflight_validations_result, python_location = run_preflight_validations(dsf_node, dsf_node_type,
                                                                                  target_version, script_file_name)
        python_location_dict[dsf_node.get('ip')] = python_location
        if are_preflight_validations_passed(preflight_validations_result):
            print(f"### Preflight validations passed for {dsf_node_type} {dsf_node.get('ip')}")
        else:
            print(f"### Preflight validations didn't pass for {dsf_node_type} {dsf_node.get('ip')}")
            return False
    return True, python_location_dict


def run_preflight_validations(dsf_node, dsf_node_type, target_version, script_file_name):
    print(f"Running preflight validations for {dsf_node_type} {dsf_node.get('ip')}")
    python_location = run_get_python_location_script(dsf_node)
    print(f"Python location in {dsf_node_type} {dsf_node.get('ip')} is {python_location}")

    preflight_validations_result_json = run_preflight_validations_script(dsf_node, target_version, python_location,
                                                                         script_file_name)
    preflight_validations_result = json.loads(preflight_validations_result_json)
    print(f"Preflight validations result in {dsf_node_type} {dsf_node.get('ip')} is {preflight_validations_result}")
    return preflight_validations_result, python_location


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
    print(f"'Run preflight validations' python script output:\n{script_output}")
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
    return preflight_validations_result.get('different_version') \
           and preflight_validations_result.get('min_version') \
           and preflight_validations_result.get('max_version_hop')


def maybe_upgrade_and_postflight(agentless_gws, hubs, target_version, run_upgrade, run_postflight_validations,
                                 python_location_dict):
    print("----- Upgrade")

    upgrade_and_postflight_succeeded = maybe_upgrade_and_postflight_dsf_nodes(agentless_gws, "Agentless Gateway",
                                                                              target_version, "upgrade_v4_10.sh",
                                                                              run_upgrade,
                                                                              run_postflight_validations,
                                                                              "run_postflight_validations.py",
                                                                              python_location_dict)
    if not upgrade_and_postflight_succeeded:
        return False
    upgrade_and_postflight_succeeded = maybe_upgrade_and_postflight_dsf_nodes(hubs, "DSF Hub", target_version,
                                                                              "upgrade_v4_10.sh",
                                                                              run_upgrade,
                                                                              run_postflight_validations,
                                                                              "run_postflight_validations.py",
                                                                              python_location_dict)
    return upgrade_and_postflight_succeeded


def maybe_upgrade_and_postflight_dsf_nodes(dsf_nodes, dsf_node_type, target_version, upgrade_script_file_name,
                                           run_upgrade, do_run_postflight_validations,
                                           postflight_validations_script_file_name, python_location_dict):
    for dsf_node in dsf_nodes:
        upgrade_succeeded = True
        if run_upgrade:
            upgrade_succeeded = upgrade_dsf_node(dsf_node, dsf_node_type, target_version, upgrade_script_file_name)
        if upgrade_succeeded:
            if do_run_postflight_validations:
                postflight_validations_result = run_postflight_validations(dsf_node, dsf_node_type, target_version,
                                                                           postflight_validations_script_file_name,
                                                                           python_location_dict[dsf_node.get('ip')])
                if are_postflight_validations_passed(postflight_validations_result):
                    print(f"### Postflight validations passed for {dsf_node_type} {dsf_node.get('ip')}")
                else:
                    print(f"### Postflight validations didn't pass for {dsf_node_type} {dsf_node.get('ip')}")
                    return False
            else:
                return True
        else:
            return False
    return True


def upgrade_dsf_node(dsf_node, dsf_node_type, target_version, upgrade_script_file_name):
    print(f"Running upgrade for {dsf_node_type} {dsf_node.get('ip')}")
    result = run_upgrade_script(dsf_node, target_version, upgrade_script_file_name)
    if result:
        print(f"Upgrading {dsf_node_type} {dsf_node.get('ip')} was ### successful ###")
    else:
        print(f"Upgrading {dsf_node_type} {dsf_node.get('ip')} ### failed ### ")
    return result


def run_upgrade_script(dsf_node, target_version, upgrade_script_file_name):
    if run_dummy_upgrade:
        print(f"Running dummy upgrade script")
        script_file_name = 'dummy_upgrade_script.sh'
    else:
        script_file_name = upgrade_script_file_name
    script_file_path = get_script_file_path(script_file_name)
    script_contents = read_file_contents(script_file_path)

    tarball = get_tarball(target_version)
    args = f"1ef8de27-ed95-40ff-8c08-7969fc1b7901 {tarball} us-east-1"
    script_run_command = build_bash_script_run_command(script_contents, args)
    # print(f"script_run_command: {script_run_command}")

    script_output = run_remote_script_maybe_with_proxy(dsf_node, script_contents, script_run_command)

    print(f"Upgrade bash script output: {script_output}")
    # This relies on the fact that Sonar outputs the string "Upgrade completed"
    return "Upgrade completed" in script_output


def get_tarball(target_version):
    return f"jsonar-{target_version}.tar.gz"


def run_postflight_validations(dsf_node, dsf_node_type, target_version, script_file_name, python_location):
    print(f"Running postflight validations for {dsf_node_type} {dsf_node.get('ip')}")
    print(f"Python location (taken from dictionary) in {dsf_node_type} {dsf_node.get('ip')} is {python_location}")

    postflight_validations_result_json = run_postflight_validations_script(dsf_node, target_version, python_location,
                                                                           script_file_name)
    postflight_validations_result = json.loads(postflight_validations_result_json)
    print(f"Postflight validations result in {dsf_node_type} {dsf_node.get('ip')} is {postflight_validations_result}")
    return postflight_validations_result


def run_postflight_validations_script(dsf_node, target_version, python_location, script_file_name):
    script_file_path = get_script_file_path(script_file_name)
    script_contents = read_file_contents(script_file_path)
    script_run_command = build_python_script_run_command(script_contents, target_version, python_location)
    # print(f"script_run_command: {script_run_command}")

    script_output = run_remote_script_maybe_with_proxy(dsf_node, script_contents, script_run_command)
    print(f"'Run postflight validations' python script output: {script_output}")
    return extract_postflight_validations_result(script_output)


def extract_postflight_validations_result(script_output):
    pattern = r'Postflight validations result: ({.+})'
    match = re.search(pattern, script_output)

    if match:
        return match.group(1)
    else:
        raise Exception("Pattern 'Postflight validations result: ...' not found in 'Run postflight validations' "
                        "script output")


def are_postflight_validations_passed(postflight_validations_result):
    return postflight_validations_result.get('correct_version')


if __name__ == "__main__":
    short_sleep_seconds = 0  # 3
    long_sleep_seconds = 0  # 5
    very_long_sleep_seconds = 0  # 10
    run_dummy_upgrade = False

    main()
