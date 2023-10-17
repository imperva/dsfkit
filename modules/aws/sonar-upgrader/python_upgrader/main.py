# main.py

import argparse
import json
import re
import socket
from utils import get_file_path, read_file_contents
from remote_executor import run_remote_script, run_remote_script_via_proxy, test_connection, test_connection_via_proxy
from upgrade_status_service import UpgradeStatusService, UpgradeStatus
from upgrade_exception import UpgradeException

# Helper functions


def str_to_bool(arg):
    # Convert string "true" or "false" to Python boolean value
    return arg.lower() == "true"


def set_socket_timeout():
    print(f"Default socket timeout: {socket.getdefaulttimeout()}")
    socket.setdefaulttimeout(CONNECTION_TIMEOUT)
    print(f"Default socket timeout was set to {CONNECTION_TIMEOUT} seconds to ensure uniform behavior across "
          f"different platforms")


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
    :return: A unique identifier of a DSF Node within this upgrader
    '''
    if dsf_node.get('proxy') is not None:
        return dsf_node.get('host') + "-via-proxy-" + dsf_node.get('proxy').get('host')
    else:
        return dsf_node.get('host')


def generate_dsf_node_name(dsf_node_type, hadr_node_type_name, dsf_node_id):
    '''
    Generates a unique DSF node name within this upgrader
    :param dsf_node_type: An Agentless Gateway or DSF Hub
    :param hadr_node_type_name Main, DR or Minor
    :param dsf_node_id Unique Id of the DSF node
    :return: A unique name of a DSF Node within this upgrader
    '''
    return f"{dsf_node_type}, {hadr_node_type_name}, {dsf_node_id}"


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
        dsf_node_name = generate_dsf_node_name(dsf_node_type, hadr_node_type_name, dsf_node_id)
        return create_extended_node(dsf_node, dsf_node_id, dsf_node_name)
    else:
        return None


def create_extended_node(dsf_node, dsf_node_id, dsf_node_name):
    return {
        "dsf_node": dsf_node,
        "dsf_node_id": dsf_node_id,
        "dsf_node_name": dsf_node_name
    }


def build_bash_script_run_command(script_contents, args=""):
    return f"sudo bash -c '{script_contents}' {args}"


def build_python_script_run_command(script_contents, args, python_location):
    return f"sudo {python_location} -c '{script_contents}' {args}"


def run_remote_script_maybe_with_proxy(dsf_node, script_contents, script_run_command):
    if dsf_node.get("proxy") is not None:
        script_output = run_remote_script_via_proxy(dsf_node.get('host'),
                                                    dsf_node.get("ssh_user"),
                                                    dsf_node.get("ssh_private_key_file_path"),
                                                    script_contents,
                                                    script_run_command,
                                                    dsf_node.get("proxy").get('host'),
                                                    dsf_node.get("proxy").get("ssh_user"),
                                                    dsf_node.get("proxy").get("ssh_private_key_file_path"),
                                                    CONNECTION_TIMEOUT)
    else:
        script_output = run_remote_script(dsf_node.get('host'),
                                          dsf_node.get("ssh_user"),
                                          dsf_node.get("ssh_private_key_file_path"),
                                          script_contents,
                                          script_run_command,
                                          CONNECTION_TIMEOUT)
    return script_output


def test_connection_maybe_with_proxy(dsf_node):
    if dsf_node.get("proxy") is not None:
        test_connection_via_proxy(dsf_node.get('host'),
                                  dsf_node.get("ssh_user"),
                                  dsf_node.get("ssh_private_key_file_path"),
                                  dsf_node.get("proxy").get('host'),
                                  dsf_node.get("proxy").get("ssh_user"),
                                  dsf_node.get("proxy").get("ssh_private_key_file_path"),
                                  CONNECTION_TIMEOUT)
    else:
        test_connection(dsf_node.get('host'),
                        dsf_node.get("ssh_user"),
                        dsf_node.get("ssh_private_key_file_path"),
                        CONNECTION_TIMEOUT)


# Main functions


def main(args):
    set_socket_timeout()

    agentless_gws = json.loads(args.agentless_gws)
    hubs = json.loads(args.dsf_hubs)
    tarball_location = json.loads(args.tarball_location)

    print("********** Inputs ************")

    print_inputs(agentless_gws, hubs, tarball_location, args)

    print("********** Start ************")

    if not args.test_connection and not args.run_preflight_validations and not args.run_upgrade and \
            not args.run_postflight_validations and not args.clean_old_deployments:
        print("All flags are disabled. Nothing to do here.")
        # TODO need to add summary here?
        return

    agentless_gw_extended_nodes = get_flat_extended_node_list(agentless_gws, "Agentless Gateway")
    dsf_hub_extended_nodes = get_flat_extended_node_list(hubs, "DSF Hub")
    extended_nodes = agentless_gw_extended_nodes + dsf_hub_extended_nodes

    upgrade_status_service = init_upgrade_status(extended_nodes, args.target_version)

    try:
        if args.test_connection:
            succeeded = test_connection_to_extended_nodes(extended_nodes, args.stop_on_failure, upgrade_status_service)
            if succeeded:
                print(f"### Test connection to all DSF nodes succeeded")

        python_location_dict = {}
        if should_run_python(args):
            python_location_dict = collect_python_locations(extended_nodes, args.stop_on_failure,
                                                            upgrade_status_service)

        # Preflight validation
        if args.run_preflight_validations:
            preflight_validations_passed = run_all_preflight_validations(agentless_gw_extended_nodes,
                                                                         dsf_hub_extended_nodes, args.target_version,
                                                                         python_location_dict, args.stop_on_failure,
                                                                         upgrade_status_service)
            if preflight_validations_passed:
                print(f"### Preflight validations passed for all DSF nodes")

        # Upgrade, postflight validations, clean old deployments
        if args.run_upgrade or args.run_postflight_validations or args.clean_old_deployments:
            success = maybe_upgrade_and_postflight(agentless_gws, hubs, args.target_version, args.run_upgrade,
                                                   args.run_postflight_validations, args.clean_old_deployments,
                                                   python_location_dict, args.stop_on_failure, tarball_location,
                                                   upgrade_status_service)
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
    except UpgradeException as e:
        print(f"### Error message: {e}")
        print(f"### An error occurred, aborting upgrade...")

    # Flush upgrade status to status file (in case of an error on the first file write, this line is the manual retry)
    upgrade_status_service.flush()

    print("********** Summary ************")
    print(upgrade_status_service.get_summary())

    print("********** End ************")


def init_upgrade_status(extended_nodes, target_version):
    upgrade_status_service = UpgradeStatusService()
    dsf_nodes_ids = [node.get('dsf_node_id') for node in extended_nodes]
    upgrade_status_service.init_upgrade_status(dsf_nodes_ids, target_version)
    return upgrade_status_service


def parse_args():
    parser = argparse.ArgumentParser(description="Upgrade script for DSF Hub and Agentless Gateway")
    parser.add_argument("--agentless_gws", help="JSON-encoded Agentless Gateway list")
    parser.add_argument("--dsf_hubs", help="JSON-encoded DSF Hub list")
    parser.add_argument("--target_version", required=True, help="Target version to upgrade")
    parser.add_argument("--connection_timeout",
                        help="Client connection timeout in seconds used for the SSH connections between the "
                             "installer machine and the DSF nodes being upgraded. Its purpose is to ensure a "
                             "uniform behavior across different platforms. Note that the SSH server in the DSF nodes "
                             "may have its own timeout configurations which may override this setting.")
    parser.add_argument("--test_connection", type=str_to_bool,
                        help="Whether to test the SSH connection to all DSF nodes being upgraded "
                             "before starting the upgrade")
    parser.add_argument("--run_preflight_validations", required=True, type=str_to_bool,
                        help="Whether to run preflight validations")
    parser.add_argument("--run_upgrade", required=True, type=str_to_bool, help="Whether to run the upgrade")
    parser.add_argument("--run_postflight_validations", required=True, type=str_to_bool,
                        help="Whether to run postflight validations")
    parser.add_argument("--clean_old_deployments", type=str_to_bool, help="Whether to clean old deployments")
    parser.add_argument("--stop_on_failure", type=str_to_bool,
                        help="Whether to stop or continue to upgrade the next DSF nodes in case of failure "
                             "on a DSF node")
    parser.add_argument("--tarball_location",
                        help="JSON-encoded S3 bucket location of the DSF installation software")
    args = parser.parse_args()
    return args


def print_inputs(agentless_gws, hubs, tarball_location, args):
    print("List of Agentless Gateways:")
    print_hadr_sets(agentless_gws)
    print("List of DSF Hubs:")
    print_hadr_sets(hubs)
    print(f"target_version: {args.target_version}")
    print(f"connection_timeout: {args.connection_timeout}")
    print(f"test_connection: {args.test_connection}")
    print(f"run_preflight_validations: {args.run_preflight_validations}")
    print(f"run_upgrade: {args.run_upgrade}")
    print(f"run_postflight_validations: {args.run_postflight_validations}")
    print(f"clean_old_deployments: {args.clean_old_deployments}")
    print(f"stop_on_failure: {args.stop_on_failure}")
    print(f"tarball_location: {tarball_location}")


def test_connection_to_extended_nodes(extended_nodes, stop_on_failure, upgrade_status_service):
    '''
    :param extended_nodes:
    :return: True if test connection to all extended DSF nodes was successful, false if it failed for at least one node
    '''
    print("----- Test connection")

    all_success_or_skip = True
    for extended_node in extended_nodes:
        success_or_skip = maybe_test_connection_to_extended_node(extended_node, stop_on_failure, upgrade_status_service)
        all_success_or_skip = all_success_or_skip and success_or_skip
    return all_success_or_skip


def maybe_test_connection_to_extended_node(extended_node, stop_on_failure, upgrade_status_service):
    if upgrade_status_service.should_test_connection(extended_node.get('dsf_node_id')):
        return test_connection_to_extended_node(extended_node, stop_on_failure, upgrade_status_service)
    return True


def test_connection_to_extended_node(extended_node, stop_on_failure, upgrade_status_service):
    '''
    Tests the SSH connection to an extended DSF node from the installer machine (where this code is run)
    :param extended_node: The node to test connection to
    :return: True if successful, false otherwise
    '''
    try:
        print(f"Running test connection to {extended_node.get('dsf_node_name')}")
        upgrade_status_service.update_upgrade_status(extended_node.get('dsf_node_id'),
                                                     UpgradeStatus.RUNNING_TEST_CONNECTION)
        test_connection_maybe_with_proxy(extended_node.get('dsf_node'))
        print(f"Test connection to {extended_node.get('dsf_node_name')} succeeded")
        upgrade_status_service.update_upgrade_status(extended_node.get('dsf_node_id'),
                                                     UpgradeStatus.TEST_CONNECTION_SUCCEEDED)
    except Exception as ex:
        print(f"Test connection to {extended_node.get('dsf_node_name')} failed with exception: {str(ex)}")
        upgrade_status_service.update_upgrade_status(extended_node.get('dsf_node_id'),
                                                     UpgradeStatus.TEST_CONNECTION_FAILED, str(ex))
        if stop_on_failure:
            raise UpgradeException(f"Test connection to {extended_node.get('dsf_node_name')} failed)")
        else:
            return False
    return True


def should_run_python(args):
    return args.run_preflight_validations or args.run_postflight_validations


def collect_python_locations(extended_nodes, stop_on_failure, upgrade_status_service):
    print("----- Collect Python location")
    python_location_dict = {}
    for extended_node in extended_nodes:
        python_location = maybe_collect_python_location(extended_node, stop_on_failure, upgrade_status_service)
        if python_location is not None:
            python_location_dict[extended_node.get('dsf_node_id')] = python_location
    return python_location_dict


def maybe_collect_python_location(extended_node, stop_on_failure, upgrade_status_service):
    if upgrade_status_service.should_collect_python_location(extended_node.get('dsf_node_id')):
        return collect_python_location(extended_node, stop_on_failure, upgrade_status_service)
    return None


def collect_python_location(extended_node, stop_on_failure, upgrade_status_service):
    try:
        upgrade_status_service.update_upgrade_status(extended_node.get('dsf_node_id'),
                                                     UpgradeStatus.RUNNING_COLLECT_PYTHON_LOCATION)
        python_location = run_get_python_location_script(extended_node.get('dsf_node'))
        print(f"Python location in {extended_node.get('dsf_node_name')} is {python_location}")
        upgrade_status_service.update_upgrade_status(extended_node.get('dsf_node_id'),
                                                     UpgradeStatus.COLLECT_PYTHON_LOCATION_SUCCEEDED)
        return python_location
    except Exception as ex:
        print(f"Collecting Python location in {extended_node.get('dsf_node_name')} failed with exception: {str(ex)}")
        upgrade_status_service.update_upgrade_status(extended_node.get('dsf_node_id'),
                                                     UpgradeStatus.COLLECT_PYTHON_LOCATION_FAILED, str(ex))
        if stop_on_failure:
            raise UpgradeException(f"Collecting Python location in {extended_node.get('dsf_node_name')} failed")
        return None


def run_all_preflight_validations(agentless_gw_extended_nodes, dsf_hub_extended_nodes, target_version,
                                  python_location_dict, stop_on_failure, upgrade_status_service):
    print("----- Preflight validations")

    gws_preflight_validations_passed = run_preflight_validations_for_extended_nodes(agentless_gw_extended_nodes,
                                                                                    target_version,
                                                                                    "run_preflight_validations.py",
                                                                                    python_location_dict,
                                                                                    stop_on_failure,
                                                                                    upgrade_status_service)
    hub_preflight_validations_passed = run_preflight_validations_for_extended_nodes(dsf_hub_extended_nodes,
                                                                                    target_version,
                                                                                    "run_preflight_validations.py",
                                                                                    python_location_dict,
                                                                                    stop_on_failure,
                                                                                    upgrade_status_service)
    return gws_preflight_validations_passed and hub_preflight_validations_passed


def run_preflight_validations_for_extended_nodes(extended_nodes, target_version, script_file_name,
                                                 python_location_dict, stop_on_failure, upgrade_status_service):
    all_success_or_skip = True
    for extended_node in extended_nodes:
        success_or_skip = maybe_run_preflight_validations_for_extended_node(extended_node, target_version,
                                                                            script_file_name, python_location_dict,
                                                                            stop_on_failure, upgrade_status_service)
        all_success_or_skip = all_success_or_skip and success_or_skip
    return all_success_or_skip


def maybe_run_preflight_validations_for_extended_node(extended_node, target_version, script_file_name,
                                                      python_location_dict, stop_on_failure, upgrade_status_service):
    if upgrade_status_service.should_run_preflight_validations(extended_node.get('dsf_node_id')):
        return run_preflight_validations_for_extended_node(extended_node, target_version, script_file_name,
                                                           python_location_dict, stop_on_failure,
                                                           upgrade_status_service)
    return True


def run_preflight_validations_for_extended_node(extended_node, target_version, script_file_name, python_location_dict,
                                                stop_on_failure, upgrade_status_service):
    python_location = python_location_dict[extended_node.get('dsf_node_id')]
    # TODO this will happen only in case of bug, do we really need it?
    if python_location is None:
        print(f"Python location not found in dictionary for {extended_node.get('dsf_node_id')}")
        upgrade_status_service.update_upgrade_status(extended_node.get('dsf_node_id'),
                                                     UpgradeStatus.PREFLIGHT_VALIDATIONS_FAILED,
                                                     "Python location not found")
        if stop_on_failure:
            raise UpgradeException(f"Python location not found in dictionary for {extended_node.get('dsf_node_id')}")
        else:
            return False

    upgrade_status_service.update_upgrade_status(extended_node.get('dsf_node_id'),
                                                 UpgradeStatus.RUNNING_PREFLIGHT_VALIDATIONS)
    preflight_validations_result = run_preflight_validations(extended_node.get('dsf_node'),
                                                             extended_node.get('dsf_node_name'), target_version,
                                                             script_file_name, python_location)
    if are_preflight_validations_passed(preflight_validations_result):
        print(f"### Preflight validations passed for {extended_node.get('dsf_node_name')}")
        upgrade_status_service.update_upgrade_status(extended_node.get('dsf_node_id'),
                                                     UpgradeStatus.PREFLIGHT_VALIDATIONS_SUCCEEDED)
    else:
        print(f"### Preflight validations didn't pass for {extended_node.get('dsf_node_name')}")
        upgrade_status_service.update_upgrade_status(extended_node.get('dsf_node_id'),
                                                     UpgradeStatus.PREFLIGHT_VALIDATIONS_FAILED,
                                                     preflight_validations_result)
        if stop_on_failure:
            raise UpgradeException(f"Preflight validations didn't pass for {extended_node.get('dsf_node_id')}")
        else:
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
           and preflight_validations_result.get('max_version_hop') \
           and preflight_validations_result.get('enough_free_disk_space')


def maybe_upgrade_and_postflight(agentless_gws, hubs, target_version, run_upgrade, run_postflight_validations,
                                 clean_old_deployments, python_location_dict, stop_on_failure, tarball_location,
                                 upgrade_status_service):
    if run_upgrade:
        print("----- Upgrade")

    gws_upgrade_and_postflight_succeeded = maybe_upgrade_and_postflight_hadr_sets(agentless_gws, "Agentless Gateway",
                                                                                  target_version, "upgrade_v4_10.sh",
                                                                                  run_upgrade,
                                                                                  run_postflight_validations,
                                                                                  "run_postflight_validations.py",
                                                                                  clean_old_deployments,
                                                                                  "clean_old_deployments.sh",
                                                                                  python_location_dict,
                                                                                  stop_on_failure,
                                                                                  tarball_location,
                                                                                  upgrade_status_service)

    hub_upgrade_and_postflight_succeeded = maybe_upgrade_and_postflight_hadr_sets(hubs, "DSF Hub", target_version,
                                                                                  "upgrade_v4_10.sh",
                                                                                  run_upgrade,
                                                                                  run_postflight_validations,
                                                                                  "run_postflight_validations.py",
                                                                                  clean_old_deployments,
                                                                                  "clean_old_deployments.sh",
                                                                                  python_location_dict,
                                                                                  stop_on_failure,
                                                                                  tarball_location,
                                                                                  upgrade_status_service)
    return gws_upgrade_and_postflight_succeeded and hub_upgrade_and_postflight_succeeded


# Used do_run_postflight_validations since there is a function called run_postflight_validations
def maybe_upgrade_and_postflight_hadr_sets(hadr_sets, dsf_node_type, target_version, upgrade_script_file_name,
                                           run_upgrade, do_run_postflight_validations,
                                           postflight_validations_script_file_name, clean_old_deployments,
                                           clean_old_deployments_script_file_name, python_location_dict,
                                           stop_on_failure, tarball_location, upgrade_status_service):
    all_success_or_skip = True
    for hadr_set in hadr_sets:
        succeed_or_skipped = maybe_upgrade_and_postflight_hadr_set(hadr_set, dsf_node_type, target_version,
                                                                   upgrade_script_file_name, run_upgrade,
                                                                   do_run_postflight_validations,
                                                                   postflight_validations_script_file_name,
                                                                   clean_old_deployments,
                                                                   clean_old_deployments_script_file_name,
                                                                   python_location_dict,
                                                                   stop_on_failure,
                                                                   tarball_location,
                                                                   upgrade_status_service)
        all_success_or_skip = all_success_or_skip and succeed_or_skipped
    return all_success_or_skip


def maybe_upgrade_and_postflight_hadr_set(hadr_set, dsf_node_type, target_version, upgrade_script_file_name,
                                          run_upgrade, do_run_postflight_validations,
                                          postflight_validations_script_file_name, clean_old_deployments,
                                          clean_old_deployments_script_file_name, python_location_dict,
                                          stop_on_failure, tarball_location, upgrade_status_service):
    if maybe_upgrade_and_postflight_dsf_node(hadr_set.get('minor'), dsf_node_type, 'Minor', target_version,
                                             upgrade_script_file_name, run_upgrade, do_run_postflight_validations,
                                             postflight_validations_script_file_name, clean_old_deployments,
                                             clean_old_deployments_script_file_name, python_location_dict,
                                             stop_on_failure, tarball_location, upgrade_status_service):
        if maybe_upgrade_and_postflight_dsf_node(hadr_set.get('dr'), dsf_node_type, 'DR', target_version,
                                                 upgrade_script_file_name, run_upgrade, do_run_postflight_validations,
                                                 postflight_validations_script_file_name, clean_old_deployments,
                                                 clean_old_deployments_script_file_name, python_location_dict,
                                                 stop_on_failure, tarball_location, upgrade_status_service):
            if maybe_upgrade_and_postflight_dsf_node(hadr_set.get('main'), dsf_node_type, 'Main', target_version,
                                                     upgrade_script_file_name, run_upgrade,
                                                     do_run_postflight_validations,
                                                     postflight_validations_script_file_name, clean_old_deployments,
                                                     clean_old_deployments_script_file_name, python_location_dict,
                                                     stop_on_failure, tarball_location, upgrade_status_service):
                return True
        else:
            print(f"Upgrade of HADR DR node failed, will not continue to Main if exists.")
    else:
        print(f"Upgrade of HADR Minor node failed, will not continue to DR and Main if exist.")
    return False


def maybe_upgrade_and_postflight_dsf_node(dsf_node, dsf_node_type, hadr_node_type_name, target_version,
                                          upgrade_script_file_name, run_upgrade, do_run_postflight_validations,
                                          postflight_validations_script_file_name, clean_old_deployments,
                                          clean_old_deployments_script_file_name, python_location_dict,
                                          stop_on_failure, tarball_location, upgrade_status_service):
    if dsf_node is None:
        return True
    # TODO refactor to use the extended node already created in previous steps
    dsf_node_id = generate_dsf_node_id(dsf_node)
    dsf_node_name = generate_dsf_node_name(dsf_node_type, hadr_node_type_name, dsf_node_id)
    extended_node = create_extended_node(dsf_node, dsf_node_id, dsf_node_name)
    if run_upgrade:
        upgrade_success_or_skip = maybe_upgrade_dsf_node(extended_node, target_version, upgrade_script_file_name,
                                                         stop_on_failure, tarball_location, upgrade_status_service)
        if not upgrade_success_or_skip:
            return False

    if do_run_postflight_validations:
        postflight_success_or_skip = maybe_run_postflight_validations(extended_node, target_version,
                                                                      postflight_validations_script_file_name,
                                                                      python_location_dict, stop_on_failure,
                                                                      upgrade_status_service)
        if not postflight_success_or_skip:
            return False

    if clean_old_deployments:
        # TODO add status support when clean_old_deployments will be supported
        clean_old_deployments_succeeded = run_clean_old_deployments(dsf_node, dsf_node_name,
                                                                    clean_old_deployments_script_file_name)
        if not clean_old_deployments_succeeded:
            # In case clean old deployments failed, print a warning without returning false
            print(f"### Warning: Cleaning old deployments failed for {dsf_node_name}")

    return True


def maybe_upgrade_dsf_node(extended_node, target_version, upgrade_script_file_name,
                           stop_on_failure, tarball_location, upgrade_status_service):
    if upgrade_status_service.should_run_upgrade(extended_node.get('dsf_node_id')):
        return upgrade_dsf_node(extended_node, target_version, upgrade_script_file_name, stop_on_failure,
                                tarball_location, upgrade_status_service)
    return True


def upgrade_dsf_node(extended_node, target_version, upgrade_script_file_name, stop_on_failure, tarball_location,
                     upgrade_status_service):
    print(f"Running upgrade for {extended_node.get('dsf_node_name')}")
    print(f"You may follow the upgrade process in the DSF node by running SSH to it and looking at "
          f"/var/log/upgrade.log. When the DSF node's upgrade will complete, this log will also appear here.")
    upgrade_status_service.update_upgrade_status(extended_node.get('dsf_node_id'),
                                                 UpgradeStatus.RUNNING_UPGRADE)
    success, script_output = run_upgrade_script(extended_node.get('dsf_node'), target_version, tarball_location,
                                                upgrade_script_file_name)
    if success:
        print(f"Upgrading {extended_node.get('dsf_node_name')} was ### successful ###")
        upgrade_status_service.update_upgrade_status(extended_node.get('dsf_node_id'),
                                                     UpgradeStatus.UPGRADE_SUCCEEDED)
    else:
        print(f"Upgrading {extended_node.get('dsf_node_name')} ### failed ### ")
        upgrade_status_service.update_upgrade_status(extended_node.get('dsf_node_id'),
                                                     UpgradeStatus.UPGRADE_FAILED, script_output)
        if stop_on_failure:
            raise UpgradeException(f"Upgrading {extended_node.get('dsf_node_name')} ### failed ### ")
    return success


def run_upgrade_script(dsf_node, target_version, tarball_location, upgrade_script_file_name):
    if run_dummy_upgrade:
        print(f"Running dummy upgrade script")
        script_file_name = 'dummy_upgrade_script.sh'
    else:
        script_file_name = upgrade_script_file_name
    script_file_path = get_file_path(script_file_name)
    script_contents = read_file_contents(script_file_path)

    args = get_upgrade_script_args(target_version, tarball_location)
    script_run_command = build_bash_script_run_command(script_contents, args)
    # print(f"script_run_command: {script_run_command}")

    script_output = run_remote_script_maybe_with_proxy(dsf_node, script_contents, script_run_command)

    print(f"Upgrade bash script output: {script_output}")
    # This relies on the fact that Sonar outputs the string "Upgrade completed"
    return "Upgrade completed" in script_output, script_output


def get_upgrade_script_args(target_version, tarball_location):
    if tarball_location.get('s3_key') is None:
        s3_key = get_tarball_s3_key(target_version)
    else:
        s3_key = tarball_location.get('s3_key')
    args = f"{tarball_location.get('s3_bucket')} {tarball_location.get('s3_region')} {s3_key}"
    return args


def get_tarball_s3_key(target_version):
    return f"jsonar-{target_version}.tar.gz"


def maybe_run_postflight_validations(extended_node, target_version, script_file_name, python_location_dict,
                                     stop_on_failure, upgrade_status_service):
    if upgrade_status_service.should_run_postflight_validations(extended_node.get('dsf_node_id')):
        return run_postflight_validations(extended_node, target_version, script_file_name, python_location_dict,
                                          stop_on_failure, upgrade_status_service)
    return True


def run_postflight_validations(extended_node, target_version, script_file_name, python_location_dict,
                               stop_on_failure, upgrade_status_service):
    python_location = python_location_dict[extended_node.get('dsf_node_id')]
    # TODO this will happen only in case of bug, do we really need it?
    if python_location is None:
        print(f"Python location not found in dictionary for {extended_node.get('dsf_node_id')}")
        upgrade_status_service.update_upgrade_status(extended_node.get('dsf_node_id'),
                                                     UpgradeStatus.POSTFLIGHT_VALIDATIONS_FAILED,
                                                     "Python location not found")
        if stop_on_failure:
            raise UpgradeException(f"Python location not found in dictionary for {extended_node.get('dsf_node_id')}")
        else:
            return False

    print(f"Running postflight validations for {extended_node.get('dsf_node_name')}")
    print(f"Python location (taken from dictionary) in {extended_node.get('dsf_node_name')} is {python_location}")

    upgrade_status_service.update_upgrade_status(extended_node.get('dsf_node_id'),
                                                 UpgradeStatus.RUNNING_POSTFLIGHT_VALIDATIONS)
    postflight_validations_result_json = run_postflight_validations_script(extended_node.get('dsf_node'),
                                                                           target_version, python_location,
                                                                           script_file_name)
    postflight_validations_result = json.loads(postflight_validations_result_json)
    print(f"Postflight validations result in {extended_node.get('dsf_node_name')} is {postflight_validations_result}")

    passed = are_postflight_validations_passed(postflight_validations_result)
    if passed:
        print(f"### Postflight validations passed for {extended_node.get('dsf_node_name')}")
        upgrade_status_service.update_upgrade_status(extended_node.get('dsf_node_id'),
                                                     UpgradeStatus.POSTFLIGHT_VALIDATIONS_SUCCEEDED)
        upgrade_status_service.update_upgrade_status(extended_node.get('dsf_node_id'),
                                                     UpgradeStatus.SUCCEEDED)
    else:
        print(f"### Postflight validations didn't pass for {extended_node.get('dsf_node_name')}")
        upgrade_status_service.update_upgrade_status(extended_node.get('dsf_node_id'),
                                                     UpgradeStatus.POSTFLIGHT_VALIDATIONS_FAILED,
                                                     postflight_validations_result)
        if stop_on_failure:
            raise UpgradeException(f"Postflight validations didn't pass for {extended_node.get('dsf_node_id')}")
    return passed


def run_postflight_validations_script(dsf_node, target_version, python_location, script_file_name):
    script_file_path = get_file_path(script_file_name)
    script_contents = read_file_contents(script_file_path)
    script_run_command = build_python_script_run_command(script_contents, target_version, python_location)
    # print(f"script_run_command: {script_run_command}")

    script_output = run_remote_script_maybe_with_proxy(dsf_node, script_contents, script_run_command)
    print(f"'Run postflight validations' python script output: {script_output}")
    return extract_postflight_validations_result(script_output)


def run_clean_old_deployments(dsf_node, dsf_node_name, script_file_name):
    print(f"Running cleaning old deployments for {dsf_node_name}")
    # print(f"You may follow the upgrade process in the DSF node by running SSH to it and looking at "
    #       f"/var/log/upgrade.log. When the DSF node's upgrade will complete, this log will also appear here.")
    success = run_clean_old_deployments_script(dsf_node, script_file_name)
    if success:
        print(f"Cleaning old deployments {dsf_node_name} was ### successful ###")
    else:
        print(f"Cleaning old deployments {dsf_node_name} ### failed ### ")
    return success


def run_clean_old_deployments_script(dsf_node, script_file_name):
    script_file_path = get_file_path(script_file_name)
    script_contents = read_file_contents(script_file_path)

    script_run_command = build_bash_script_run_command(script_contents)
    # print(f"script_run_command: {script_run_command}")

    script_output = run_remote_script_maybe_with_proxy(dsf_node, script_contents, script_run_command)

    print(f"Cleaning old deployments bash script output: {script_output}")
    # TODO need to determine how to recognize that the clean command succeeded after implementing it
    return "Clean old deployments bash script completed" in script_output


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
    args = parse_args()

    CONNECTION_TIMEOUT = int(args.connection_timeout)

    main(args)
