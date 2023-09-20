# main.py

import argparse
import json
import re
from utils import get_file_path, read_file_contents
from remote_executor import run_remote_script, run_remote_script_via_proxy


# Helper functions


def str_to_bool(arg):
    # Convert string "true" or "false" to Python boolean value
    return arg.lower() == "true"


def print_hadr_sets(hadr_sets):
    '''
    An HADR set is a subnet of main, DR and minor.
    '''
    print("---")
    for hadr_set in hadr_sets:
        print_hadr_set(hadr_set)
        print("---")


def print_hadr_set(hadr_set):
    if hadr_set.get('main') is not None:
        print(f"Main:")
        print_dsf_node(hadr_set.get('main'))
    if hadr_set.get('dr') is not None:
        print(f"DR:")
        print_dsf_node(hadr_set.get('dr'))
    if hadr_set.get('minor') is not None:
        print(f"Minor:")
        print_dsf_node(hadr_set.get('minor'))


def print_dsf_node(dsf_node):
    print(f"    Host: {dsf_node.get('host')}")
    print(f"    SSH User: {dsf_node.get('ssh_user')}")
    print(f"    SSH Key: {dsf_node.get('ssh_private_key_file_path')}")
    print(f"    Proxy: {dsf_node.get('proxy')}")


def generate_dsf_node_id(dsf_node):
    '''
    Generates a unique identifier of the DSF node within this upgrader
    :param dsf_node: An Agentless Gateway or DSF Hub
    :return: A unique identifier of the dsf_node within this upgrader
    '''
    if dsf_node.get('proxy') is not None:
        return dsf_node.get('host') + "-via-proxy-" + dsf_node.get('proxy').get('host')
    else:
        return dsf_node.get('host')


def get_flat_extended_node_list(hadr_sets, dsf_node_type):
    extended_nodes = []
    for hadr_set in hadr_sets:
        main_node = get_extended_node(hadr_set, 'main', 'Main', dsf_node_type)
        if main_node is not None:
            extended_nodes.append(main_node)
        dr_node = get_extended_node(hadr_set, 'dr', 'DR', dsf_node_type)
        if dr_node is not None:
            extended_nodes.append(dr_node)
        minor_node = get_extended_node(hadr_set, 'minor', 'Minor', dsf_node_type)
        if minor_node is not None:
            extended_nodes.append(minor_node)
    return extended_nodes


def get_extended_node(hadr_set, hadr_node_type, hadr_node_type_name, dsf_node_type):
    dsf_node = hadr_set.get(hadr_node_type)
    if dsf_node is not None:
        dsf_node_id = generate_dsf_node_id(dsf_node)
        dsf_node_name = f"{dsf_node_type}, HADR {hadr_node_type_name}, {dsf_node_id}"
        return {
            "dsf_node": dsf_node,
            "dsf_node_id": dsf_node_id,
            "dsf_node_name": dsf_node_name
        }
    else:
        return None


def build_bash_script_run_command(script_contents, args=""):
    return f"sudo bash -c '{script_contents}' {args}"


def build_python_script_run_command(script_contents, args, python_location):
    return f"sudo {python_location} -c '{script_contents}' {args}"


def run_remote_script_maybe_with_proxy(agentless_gw, script_contents, script_run_command):
    if agentless_gw.get("proxy") is not None:
        script_output = run_remote_script_via_proxy(agentless_gw.get('host'),
                                                    agentless_gw.get("ssh_user"),
                                                    agentless_gw.get("ssh_private_key_file_path"),
                                                    script_contents,
                                                    script_run_command,
                                                    agentless_gw.get("proxy").get('host'),
                                                    agentless_gw.get("proxy").get("ssh_user"),
                                                    agentless_gw.get("proxy").get("ssh_private_key_file_path"))
    else:
        script_output = run_remote_script(agentless_gw.get('host'),
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

    if not args.run_preflight_validations and not args.run_upgrade and not args.run_postflight_validations and \
            not args.run_clean_old_deployments:
        print("All flags are disabled. Nothing to do here.")
        return

    agentless_gw_extended_nodes = get_flat_extended_node_list(agentless_gws, "Agentless Gateway")
    dsf_hub_extended_nodes = get_flat_extended_node_list(hubs, "DSF Hub")
    extended_nodes = agentless_gw_extended_nodes + dsf_hub_extended_nodes
    python_location_dict = collect_python_locations(extended_nodes)

    # Preflight validation
    if args.run_preflight_validations:
        preflight_validations_passed = run_all_preflight_validations(agentless_gw_extended_nodes,
                                                                     dsf_hub_extended_nodes, args.target_version,
                                                                     python_location_dict)
        if preflight_validations_passed:
            print(f"### Preflight validations passed")
        else:
            print(f"### Preflight validations failed, aborting upgrade...")
            return

    # Upgrade, postflight validations, clean old deployments
    if args.run_upgrade or args.run_postflight_validations or args.run_clean_old_deployments:
        success = maybe_upgrade_and_postflight(agentless_gws, hubs, args.target_version, args.run_upgrade,
                                               args.run_postflight_validations, args.run_clean_old_deployments,
                                               python_location_dict)
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
    parser.add_argument("--run_preflight_validations", required=True, type=str_to_bool,
                        help="Whether to run preflight validations")
    parser.add_argument("--run_upgrade", required=True, type=str_to_bool, help="Whether to run the upgrade")
    parser.add_argument("--run_postflight_validations", required=True, type=str_to_bool,
                        help="Whether to run postflight validations")
    parser.add_argument("--run_clean_old_deployments", required=True, type=str_to_bool,
                        help="Whether to run cleaning on old deployment directories")
    parser.add_argument("--custom_validations_scripts", help="List of custom validation scripts")
    args = parser.parse_args()
    return args


def print_inputs(agentless_gws, hubs, args):
    print("List of Agentless Gateways:")
    print_hadr_sets(agentless_gws)
    print("List of DSF Hubs:")
    print_hadr_sets(hubs)
    print(f"target_version: {args.target_version}")
    print(f"run_preflight_validations: {args.run_preflight_validations}")
    print(f"run_upgrade: {args.run_upgrade}")
    print(f"run_postflight_validations: {args.run_postflight_validations}")
    print(f"run_clean_old_deployments: {args.run_clean_old_deployments}")
    print(f"custom_validations_scripts: {args.custom_validations_scripts}")


def collect_python_locations(extended_nodes):
    python_location_dict = {}
    for extended_node in extended_nodes:
        python_location = run_get_python_location_script(extended_node.get('dsf_node'))
        # TODO host is not unique, need id
        python_location_dict[extended_node.get('dsf_node').get('host')] = python_location
        print(f"Python location in {extended_node.get('dsf_node_name')} is {python_location}")
    return python_location_dict


def run_all_preflight_validations(agentless_gw_extended_nodes, dsf_hub_extended_nodes, target_version,
                                  python_location_dict):
    print("----- Preflight validations")

    preflight_validations_passed = run_preflight_validations_for_extended_nodes(agentless_gw_extended_nodes,
                                                                                target_version,
                                                                                "run_preflight_validations.py",
                                                                                python_location_dict)
    if not preflight_validations_passed:
        return False
    preflight_validations_passed = run_preflight_validations_for_extended_nodes(dsf_hub_extended_nodes, target_version,
                                                                                "run_preflight_validations.py",
                                                                                python_location_dict)
    return preflight_validations_passed


def run_preflight_validations_for_extended_nodes(extended_nodes, target_version, script_file_name,
                                                 python_location_dict):
    for extended_node in extended_nodes:
        success = run_preflight_validations_for_extended_node(extended_node, target_version, script_file_name,
                                                              python_location_dict)
        if not success:
            return False
    return True


def run_preflight_validations_for_extended_node(extended_node, target_version, script_file_name, python_location_dict):
    # TODO host is not unique, need id
    python_location = python_location_dict[extended_node.get('dsf_node').get('host')]

    preflight_validations_result = run_preflight_validations(extended_node.get('dsf_node'),
                                                             extended_node.get('dsf_node_name'), target_version,
                                                             script_file_name, python_location)
    if are_preflight_validations_passed(preflight_validations_result):
        print(f"### Preflight validations passed for {extended_node.get('dsf_node_name')}")
    else:
        print(f"### Preflight validations didn't pass for {extended_node.get('dsf_node_name')}")
        return False
    return True


def run_preflight_validations(dsf_node, dsf_node_name, target_version, script_file_name, python_location):
    print(f"Running preflight validations for {dsf_node_name}")

    preflight_validations_result_json = run_preflight_validations_script(dsf_node, target_version, python_location,
                                                                         script_file_name)
    preflight_validations_result = json.loads(preflight_validations_result_json)
    print(f"Preflight validations result in {dsf_node_name} is {preflight_validations_result}")
    return preflight_validations_result


def run_get_python_location_script(dsf_node):
    script_file_path = get_file_path("get_python_location.sh")
    script_contents = read_file_contents(script_file_path)
    script_run_command = build_bash_script_run_command(script_contents)

    print(f"Getting python location for DSF node: {dsf_node}")
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
    script_file_path = get_file_path(script_file_name)
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
                                 run_clean_old_deployments, python_location_dict):
    if run_upgrade:
        print("----- Upgrade")

    upgrade_and_postflight_succeeded = maybe_upgrade_and_postflight_hadr_sets(agentless_gws, "Agentless Gateway",
                                                                              target_version, "upgrade_v4_10.sh",
                                                                              run_upgrade,
                                                                              run_postflight_validations,
                                                                              "run_postflight_validations.py",
                                                                              run_clean_old_deployments,
                                                                              "clean_old_deployments.sh",
                                                                              python_location_dict)
    if not upgrade_and_postflight_succeeded:
        return False
    upgrade_and_postflight_succeeded = maybe_upgrade_and_postflight_hadr_sets(hubs, "DSF Hub", target_version,
                                                                              "upgrade_v4_10.sh",
                                                                              run_upgrade,
                                                                              run_postflight_validations,
                                                                              "run_postflight_validations.py",
                                                                              run_clean_old_deployments,
                                                                              "clean_old_deployments.sh",
                                                                              python_location_dict)
    return upgrade_and_postflight_succeeded


def maybe_upgrade_and_postflight_hadr_sets(hadr_sets, dsf_node_type, target_version, upgrade_script_file_name,
                                           run_upgrade, do_run_postflight_validations,
                                           postflight_validations_script_file_name, run_clean_old_deployments,
                                           clean_old_deployments_script_file_name, python_location_dict):
    for hadr_set in hadr_sets:
        succeeded = maybe_upgrade_and_postflight_hadr_set(hadr_set, dsf_node_type, target_version,
                                                          upgrade_script_file_name, run_upgrade,
                                                          do_run_postflight_validations,
                                                          postflight_validations_script_file_name,
                                                          run_clean_old_deployments,
                                                          clean_old_deployments_script_file_name, python_location_dict)
        if not succeeded:
            return False
    return True


def maybe_upgrade_and_postflight_hadr_set(hadr_set, dsf_node_type, target_version, upgrade_script_file_name,
                                          run_upgrade, do_run_postflight_validations,
                                          postflight_validations_script_file_name, run_clean_old_deployments,
                                          clean_old_deployments_script_file_name, python_location_dict):
    print(f"Running upgrade and/or postflight validations for an {dsf_node_type} HADR replica set")
    if maybe_upgrade_and_postflight_dsf_node(hadr_set.get('minor'), dsf_node_type, 'Minor', target_version,
                                             upgrade_script_file_name, run_upgrade, do_run_postflight_validations,
                                             postflight_validations_script_file_name, run_clean_old_deployments,
                                             clean_old_deployments_script_file_name, python_location_dict):
        if maybe_upgrade_and_postflight_dsf_node(hadr_set.get('dr'), dsf_node_type, 'DR', target_version,
                                                 upgrade_script_file_name, run_upgrade, do_run_postflight_validations,
                                                 postflight_validations_script_file_name, run_clean_old_deployments,
                                                 clean_old_deployments_script_file_name, python_location_dict):
            if maybe_upgrade_and_postflight_dsf_node(hadr_set.get('main'), dsf_node_type, 'Main', target_version,
                                                     upgrade_script_file_name, run_upgrade,
                                                     do_run_postflight_validations,
                                                     postflight_validations_script_file_name, run_clean_old_deployments,
                                                     clean_old_deployments_script_file_name, python_location_dict):
                return True
        else:
            print(f"Upgrade of HADR DR node failed, will not continue to Main if exists.")
    else:
        print(f"Upgrade of HADR Minor node failed, will not continue to DR and Main if exist.")
    return False


def maybe_upgrade_and_postflight_dsf_node(dsf_node, dsf_node_type, hadr_node_type_name, target_version,
                                          upgrade_script_file_name, run_upgrade, do_run_postflight_validations,
                                          postflight_validations_script_file_name, run_clean_old_deployments,
                                          clean_old_deployments_script_file_name, python_location_dict):
    if dsf_node is None:
        return True
    dsf_node_id = generate_dsf_node_id(dsf_node)
    # TODO consider extracting method generate_dsf_node_name since called twice
    dsf_node_name = f"{dsf_node_type}, HADR {hadr_node_type_name}, {dsf_node_id}"
    if run_upgrade:
        upgrade_succeeded = upgrade_dsf_node(dsf_node, dsf_node_name, target_version, upgrade_script_file_name)
        if not upgrade_succeeded:
            return False

    if do_run_postflight_validations:
        postflight_validations_result = run_postflight_validations(dsf_node, dsf_node_name, target_version,
                                                                   postflight_validations_script_file_name,
                                                                   # TODO host is not unique, need the id
                                                                   python_location_dict[dsf_node.get('host')])
        if are_postflight_validations_passed(postflight_validations_result):
            print(f"### Postflight validations passed for {dsf_node_name}")
        else:
            print(f"### Postflight validations didn't pass for {dsf_node_name}")
            return False

    if run_clean_old_deployments:
        clean_old_deployments_succeeded = run_clean_old_deployment_directories(dsf_node, dsf_node_name,
                                                                               clean_old_deployments_script_file_name)
        if not clean_old_deployments_succeeded:
            # In case clean old deployments failed, print a warning without returning false
            print(f"### Warning: Cleaning old deployments failed for {dsf_node_name}")

    return True


def upgrade_dsf_node(dsf_node, dsf_node_name, target_version, upgrade_script_file_name):
    print(f"Running upgrade for {dsf_node_name}")
    print(f"You may follow the upgrade process in the DSF node by running SSH to it and looking at "
          f"/var/log/upgrade.log. When the DSF node's upgrade will complete, this log will also appear here.")
    success = run_upgrade_script(dsf_node, target_version, upgrade_script_file_name)
    if success:
        print(f"Upgrading {dsf_node_name} was ### successful ###")
    else:
        print(f"Upgrading {dsf_node_name} ### failed ### ")
    return success


def run_upgrade_script(dsf_node, target_version, upgrade_script_file_name):
    if run_dummy_upgrade:
        print(f"Running dummy upgrade script")
        script_file_name = 'dummy_upgrade_script.sh'
    else:
        script_file_name = upgrade_script_file_name
    script_file_path = get_file_path(script_file_name)
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


def run_postflight_validations(dsf_node, dsf_node_name, target_version, script_file_name, python_location):
    print(f"Running postflight validations for {dsf_node_name}")
    print(f"Python location (taken from dictionary) in {dsf_node_name} is {python_location}")

    postflight_validations_result_json = run_postflight_validations_script(dsf_node, target_version, python_location,
                                                                           script_file_name)
    postflight_validations_result = json.loads(postflight_validations_result_json)
    print(f"Postflight validations result in {dsf_node_name} is {postflight_validations_result}")
    return postflight_validations_result


def run_postflight_validations_script(dsf_node, target_version, python_location, script_file_name):
    script_file_path = get_file_path(script_file_name)
    script_contents = read_file_contents(script_file_path)
    script_run_command = build_python_script_run_command(script_contents, target_version, python_location)
    # print(f"script_run_command: {script_run_command}")

    script_output = run_remote_script_maybe_with_proxy(dsf_node, script_contents, script_run_command)
    print(f"'Run postflight validations' python script output: {script_output}")
    return extract_postflight_validations_result(script_output)


def run_clean_old_deployment_directories(dsf_node, dsf_node_name, script_file_name):
    print(f"Running cleaning old deployments for {dsf_node_name}")
    # print(f"You may follow the upgrade process in the DSF node by running SSH to it and looking at "
    #       f"/var/log/upgrade.log. When the DSF node's upgrade will complete, this log will also appear here.")
    success = run_clean_old_deployment_directories_script(dsf_node, script_file_name)
    if success:
        print(f"Cleaning old deployments {dsf_node_name} was ### successful ###")
    else:
        print(f"Cleaning old deployments {dsf_node_name} ### failed ### ")
    return success


def run_clean_old_deployment_directories_script(dsf_node, script_file_name):
    script_file_path = get_file_path(script_file_name)
    script_contents = read_file_contents(script_file_path)

    script_run_command = build_bash_script_run_command(script_contents)
    # print(f"script_run_command: {script_run_command}")

    script_output = run_remote_script_maybe_with_proxy(dsf_node, script_contents, script_run_command)

    print(f"Cleaning old deployments bash script output: {script_output}")
    # This relies on the fact that Sonar outputs the string "Upgrade completed"
    return "Cleaning old deployments completed" in script_output


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
    run_dummy_upgrade = False

    main()
