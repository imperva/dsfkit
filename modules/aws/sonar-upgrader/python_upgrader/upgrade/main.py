# main.py

import argparse
import json
import os
import re
import socket
from itertools import chain

from .remote_executor import remote_client_context, run_remote_script as run_remote_script_timeout
from .upgrade_exception import UpgradeException
from .upgrade_status_service import OverallUpgradeStatus, UpgradeStatus, UpgradeStatusService
from .utils.file_utils import join_paths, read_file_contents

# Constants
PREFLIGHT_VALIDATIONS_SCRIPT_NAME = "run_preflight_validations.py"
UPGRADE_SCRIPT_NAME = "upgrade_v4_10.sh"
POSTFLIGHT_VALIDATIONS_SCRIPT_NAME = "run_postflight_validations.py"
CLEAN_OLD_DEPLOYMENTS_SCRIPT_NAME = "clean_old_deployments.sh"

SONAR_INSTALLATION_S3_PREFIX = "sonar"

UNDEFINED_PYTHON_LOCATION = "UNDEFINED_PYTHON_LOCATION"

# Globals
_connection_timeout = None
_run_dummy_upgrade = False

# Helper functions


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


def build_script_file_path(script_file_name):
    file_dir = get_current_directory()
    return join_paths(file_dir, "scripts", script_file_name)


def get_current_directory():
    # Get the absolute path of the currently executing script
    return os.path.dirname(os.path.abspath(__file__))


def str_to_bool(arg):
    # Convert string "true" or "false" to Python boolean value
    return arg.lower() == "true"


def set_socket_timeout():
    print(f"Default socket timeout: {socket.getdefaulttimeout()}")
    socket.setdefaulttimeout(_connection_timeout)
    print(f"Default socket timeout was set to {_connection_timeout} seconds to ensure uniform behavior across "
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


def get_extended_node_dict(hadr_sets, dsf_node_type):
    extended_nodes = {}
    for hadr_set in hadr_sets:
        main_node = get_extended_node(hadr_set, 'main', 'Main', dsf_node_type)
        if main_node is not None:
            extended_nodes[main_node.get('dsf_node_id')] = main_node
        dr_node = get_extended_node(hadr_set, 'dr', 'DR', dsf_node_type)
        if dr_node is not None:
            extended_nodes[dr_node.get('dsf_node_id')] = dr_node
        minor_node = get_extended_node(hadr_set, 'minor', 'Minor', dsf_node_type)
        if minor_node is not None:
            extended_nodes[minor_node.get('dsf_node_id')] = minor_node
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
        "dsf_node_name": dsf_node_name,
        "python_location": UNDEFINED_PYTHON_LOCATION  # Will be filled later
    }


def build_bash_script_run_command(script_contents, args=""):
    return f"sudo bash -c '{script_contents}' {args}"


def build_python_script_run_command(script_contents, args, python_location):
    return f"sudo {python_location} -c '{script_contents}' {args}"


def run_remote_script(dsf_node, script_contents, script_run_command):
    return run_remote_script_timeout(dsf_node, script_contents, script_run_command, _connection_timeout)


def test_connection(dsf_node):
    with remote_client_context(dsf_node, _connection_timeout) as client:
        client.exec_command('echo yes')


def print_summary(upgrade_status_service, overall_upgrade_status=None):
    summary = upgrade_status_service.get_summary(overall_upgrade_status)
    print("********** Summary ************")
    print(summary)


# Main functions


def main(args):
    set_socket_timeout()

    agentless_gws = json.loads(args.agentless_gws)
    hubs = json.loads(args.dsf_hubs)
    tarball_location = json.loads(args.tarball_location)

    print("********** Inputs ************")

    print_inputs(agentless_gws, hubs, tarball_location, args)

    print("********** Start ************")

    agentless_gw_extended_node_dict = get_extended_node_dict(agentless_gws, "Agentless Gateway")
    dsf_hub_extended_node_dict = get_extended_node_dict(hubs, "DSF Hub")
    extended_node_dict = {**agentless_gw_extended_node_dict, **dsf_hub_extended_node_dict}

    upgrade_status_service = init_upgrade_status(extended_node_dict, args.target_version)

    if is_empty_run(args, upgrade_status_service):
        return

    try:
        run_upgrade_stages(args, extended_node_dict, agentless_gw_extended_node_dict, dsf_hub_extended_node_dict,
                           agentless_gws, hubs, tarball_location, upgrade_status_service)
    except UpgradeException as e:
        print(f"### Error message: {e}")
        print(f"### An error occurred, aborting upgrade...")

    # Flush upgrade status to status file (in case of an error on the first file write, this line is the manual retry)
    upgrade_status_service.flush()

    overall_upgrade_status = upgrade_status_service.get_overall_upgrade_status()
    print_summary(upgrade_status_service, overall_upgrade_status)

    print("********** End ************")

    is_run_successful = verify_successful_run(overall_upgrade_status, args, upgrade_status_service)
    if is_run_successful is False:
        raise UpgradeException("One of the upgrade stages failed")


def init_upgrade_status(extended_node_dict, target_version):
    upgrade_status_service = UpgradeStatusService()
    dsf_nodes_ids = list(extended_node_dict)
    upgrade_status_service.init_upgrade_status(dsf_nodes_ids, target_version)
    return upgrade_status_service


def is_empty_run(args, upgrade_status_service):
    if not args.test_connection and not args.run_preflight_validations and not args.run_upgrade and \
            not args.run_postflight_validations and not args.clean_old_deployments:
        print("All flags are disabled. Nothing to do here.")
        print_summary(upgrade_status_service)
        return True
    return False


def run_upgrade_stages(args, extended_node_dict, agentless_gw_extended_node_dict, dsf_hub_extended_node_dict,
                       agentless_gws, hubs, tarball_location, upgrade_status_service):
    """
    Runs the various upgrade stages:
    - Test connection for all nodes
    - Preflight validations for all nodes
    - Upgrade and post upgrade operations per node:
        - Upgrade
        - Postflight validations
        - Clean old deployments
    Also runs upgrade steps which are smaller than stages:
        - Collect python location for all nodes
    """
    run_test_connection_stage(args, extended_node_dict, upgrade_status_service)

    run_collect_node_info_step(args, extended_node_dict, upgrade_status_service)

    run_preflight_validations_stage(args, agentless_gw_extended_node_dict, dsf_hub_extended_node_dict,
                                    upgrade_status_service)

    run_upgrade_and_post_upgrade_stages(args, agentless_gws, hubs, extended_node_dict, tarball_location,
                                        upgrade_status_service)


def run_test_connection_stage(args, extended_node_dict, upgrade_status_service):
    if args.test_connection:
        succeeded = test_connection_to_extended_nodes(extended_node_dict, args.stop_on_failure, upgrade_status_service)
        if succeeded:
            print(f"### Test connection to all DSF nodes succeeded")


def run_collect_node_info_step(args, extended_node_dict, upgrade_status_service):

    for extended_node in extended_node_dict.values():
        if upgrade_status_service.should_collect_node_info(extended_node.get('dsf_node_id')):
            upgrade_status_service.update_upgrade_status(extended_node.get('dsf_node_id'),
                                                         UpgradeStatus.RUNNING_COLLECT_NODE_INFO)
            try:
                collect_node_info(extended_node)
                upgrade_status_service.update_upgrade_status(extended_node.get('dsf_node_id'),
                                                             UpgradeStatus.COLLECT_NODE_INFO_SUCCEEDED)
            except Exception as e:
                upgrade_status_service.update_upgrade_status(extended_node.get('dsf_node_id'),
                                                             UpgradeStatus.COLLECT_NODE_INFO_FAILED)
                if args.stop_on_failure:
                    raise UpgradeException(
                        f"Collecting Python location in {extended_node.get('dsf_node_name')} failed") from e


def collect_node_info(extended_node):

    with remote_client_context(extended_node.get('dsf_node'), _connection_timeout) as client:
        collect_sysconfig(extended_node, client)
        collect_python_location(extended_node)


def collect_sysconfig(extended_node, client):
    sftp_client = client.open_sftp()
    remote_file = sftp_client.open('/etc/sysconfig/jsonar')
    extended_node['sysconfig'] = {}
    for line in remote_file:
        if line.strip():
            key, value = line.split("=")
            extended_node['sysconfig'][key.strip()] = value.strip()


def collect_python_location(extended_node):
    extended_node['python_location'] = f"{extended_node['sysconfig']['JSONAR_BASEDIR']}/bin/python3"


def run_preflight_validations_stage(args, agentless_gw_extended_node_dict, dsf_hub_extended_node_dict,
                                    upgrade_status_service):
    if args.run_preflight_validations:
        preflight_validations_passed = run_preflight_validations(args.stop_on_failure, args.target_version,
                                                                 agentless_gw_extended_node_dict,
                                                                 dsf_hub_extended_node_dict, upgrade_status_service)
        if preflight_validations_passed:
            print(f"### Preflight validations passed for all DSF nodes")


def run_upgrade_and_post_upgrade_stages(args, agentless_gws, hubs, extended_node_dict, tarball_location,
                                        upgrade_status_service):
    if args.run_upgrade or args.run_postflight_validations or args.clean_old_deployments:
        success = maybe_upgrade_and_postflight(agentless_gws, hubs, extended_node_dict, args.target_version,
                                               args.run_upgrade, args.run_postflight_validations,
                                               args.clean_old_deployments, args.stop_on_failure, tarball_location,
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


def test_connection_to_extended_nodes(extended_node_dict, stop_on_failure, upgrade_status_service):
    '''
    :param extended_node_dict:
    :return: True if test connection to all extended DSF nodes was successful, false if it failed for at least one node
    '''
    print("----- Test connection")

    all_success_or_skip = True
    for extended_node in extended_node_dict.values():
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
        test_connection(extended_node.get('dsf_node'))
        print(f"Test connection to {extended_node.get('dsf_node_name')} succeeded")
        upgrade_status_service.update_upgrade_status(extended_node.get('dsf_node_id'),
                                                     UpgradeStatus.TEST_CONNECTION_SUCCEEDED)
    except Exception as ex:
        print(f"Test connection to {extended_node.get('dsf_node_name')} failed with exception: {str(ex)}")
        upgrade_status_service.update_upgrade_status(extended_node.get('dsf_node_id'),
                                                     UpgradeStatus.TEST_CONNECTION_FAILED, str(ex))
        if stop_on_failure:
            raise UpgradeException(f"Test connection to {extended_node.get('dsf_node_name')} failed)") from ex
        else:
            return False
    return True


def run_preflight_validations(stop_on_failure, target_version, agentless_gw_extended_node_dict,
                              dsf_hub_extended_node_dict, upgrade_status_service):
    print("----- Preflight validations")

    successful = True
    for extended_node in chain(agentless_gw_extended_node_dict.values(), dsf_hub_extended_node_dict.values()):
        if upgrade_status_service.should_run_preflight_validations(extended_node.get('dsf_node_id')):
            node_successful = run_preflight_validations_for_node(stop_on_failure, target_version, extended_node, upgrade_status_service)
            successful = successful and node_successful

    return successful


def run_preflight_validations_for_node(stop_on_failure, target_version, extended_node, upgrade_status_service):
    error_message = None
    try:
        upgrade_status_service.update_upgrade_status(
            extended_node.get('dsf_node_id'), UpgradeStatus.RUNNING_PREFLIGHT_VALIDATIONS,
        )
        preflight_validations_result = run_preflight_validations_script(
            target_version, extended_node.get('dsf_node'), extended_node.get('dsf_node_name'), extended_node.get('python_location'),
        )

        if are_preflight_validations_passed(preflight_validations_result):
            print(f"### Preflight validations passed for {extended_node.get('dsf_node_name')}")
            upgrade_status_service.update_upgrade_status(
                extended_node.get('dsf_node_id'), UpgradeStatus.PREFLIGHT_VALIDATIONS_SUCCEEDED,
            )
        else:
            print(f"### Preflight validations didn't pass for {extended_node.get('dsf_node_name')}")
            error_message = preflight_validations_result
    except Exception as ex:
        print(f"### Preflight validations for {extended_node.get('dsf_node_name')} failed with exception: {str(ex)}")
        error_message = str(ex)

    if error_message is not None:
        upgrade_status_service.update_upgrade_status(
            extended_node.get('dsf_node_id'), UpgradeStatus.PREFLIGHT_VALIDATIONS_FAILED,
            error_message,
        )
        if stop_on_failure:
            raise UpgradeException(f"Preflight validations didn't pass for {extended_node.get('dsf_node_id')}")
        else:
            return False
    return True


def run_preflight_validations_script(target_version, dsf_node, dsf_node_name, python_location):
    print(f"Running preflight validations for {dsf_node_name}")
    script_file_path = build_script_file_path(PREFLIGHT_VALIDATIONS_SCRIPT_NAME)
    script_contents = read_file_contents(script_file_path)
    script_run_command = build_python_script_run_command(script_contents, target_version, python_location)
    # print(f"script_run_command: {script_run_command}")

    script_output = run_remote_script(dsf_node, script_contents, script_run_command)
    print(f"'Run preflight validations' python script output:\n{script_output}")

    preflight_validations_result = json.loads(extract_preflight_validations_result(script_output))
    print(f"Preflight validations result in {dsf_node_name} is {preflight_validations_result}")
    return preflight_validations_result


def extract_preflight_validations_result(script_output):
    pattern = r'Preflight validations result: ({.+})'
    match = re.search(pattern, script_output)

    if match:
        return match.group(1)
    else:
        raise Exception("Pattern 'Preflight validations result: ...' not found in 'Run preflight validations' "
                        "script output")


def are_preflight_validations_passed(preflight_validations_result):
    return preflight_validations_result.get('higher_target_version') \
           and preflight_validations_result.get('min_version') \
           and preflight_validations_result.get('max_version_hop') \
           and preflight_validations_result.get('enough_free_disk_space')


# Used do_run_postflight_validations since there is a function called run_postflight_validations
def maybe_upgrade_and_postflight(agentless_gws, hubs, extended_node_dict, target_version, run_upgrade,
                                 do_run_postflight_validations, clean_old_deployments, stop_on_failure,
                                 tarball_location, upgrade_status_service):
    if run_upgrade:
        print("----- Upgrade")

    gws_upgrade_and_postflight_succeeded = maybe_upgrade_and_postflight_hadr_sets(agentless_gws, "Agentless Gateway",
                                                                                  extended_node_dict,
                                                                                  target_version,
                                                                                  UPGRADE_SCRIPT_NAME,
                                                                                  run_upgrade,
                                                                                  do_run_postflight_validations,
                                                                                  POSTFLIGHT_VALIDATIONS_SCRIPT_NAME,
                                                                                  clean_old_deployments,
                                                                                  CLEAN_OLD_DEPLOYMENTS_SCRIPT_NAME,
                                                                                  stop_on_failure,
                                                                                  tarball_location,
                                                                                  upgrade_status_service)

    hub_upgrade_and_postflight_succeeded = maybe_upgrade_and_postflight_hadr_sets(hubs, "DSF Hub",
                                                                                  extended_node_dict,
                                                                                  target_version,
                                                                                  UPGRADE_SCRIPT_NAME,
                                                                                  run_upgrade,
                                                                                  do_run_postflight_validations,
                                                                                  POSTFLIGHT_VALIDATIONS_SCRIPT_NAME,
                                                                                  clean_old_deployments,
                                                                                  CLEAN_OLD_DEPLOYMENTS_SCRIPT_NAME,
                                                                                  stop_on_failure,
                                                                                  tarball_location,
                                                                                  upgrade_status_service)
    return gws_upgrade_and_postflight_succeeded and hub_upgrade_and_postflight_succeeded


def maybe_upgrade_and_postflight_hadr_sets(hadr_sets, dsf_node_type, extended_node_dict, target_version,
                                           upgrade_script_file_name, run_upgrade, do_run_postflight_validations,
                                           postflight_validations_script_file_name, clean_old_deployments,
                                           clean_old_deployments_script_file_name,
                                           stop_on_failure, tarball_location, upgrade_status_service):
    all_success_or_skip = True
    for hadr_set in hadr_sets:
        succeed_or_skipped = maybe_upgrade_and_postflight_hadr_set(hadr_set, dsf_node_type, extended_node_dict,
                                                                   target_version,
                                                                   upgrade_script_file_name, run_upgrade,
                                                                   do_run_postflight_validations,
                                                                   postflight_validations_script_file_name,
                                                                   clean_old_deployments,
                                                                   clean_old_deployments_script_file_name,
                                                                   stop_on_failure,
                                                                   tarball_location,
                                                                   upgrade_status_service)
        all_success_or_skip = all_success_or_skip and succeed_or_skipped
    return all_success_or_skip


def maybe_upgrade_and_postflight_hadr_set(hadr_set, dsf_node_type, extended_node_dict, target_version,
                                          upgrade_script_file_name, run_upgrade, do_run_postflight_validations,
                                          postflight_validations_script_file_name, clean_old_deployments,
                                          clean_old_deployments_script_file_name,
                                          stop_on_failure, tarball_location, upgrade_status_service):
    print(f"Checking if running upgrade and/or postflight validations is required for {dsf_node_type} set")
    if maybe_upgrade_and_postflight_dsf_node(hadr_set.get('minor'), extended_node_dict, target_version,
                                             upgrade_script_file_name, run_upgrade, do_run_postflight_validations,
                                             postflight_validations_script_file_name, clean_old_deployments,
                                             clean_old_deployments_script_file_name,
                                             stop_on_failure, tarball_location, upgrade_status_service):
        if maybe_upgrade_and_postflight_dsf_node(hadr_set.get('dr'), extended_node_dict, target_version,
                                                 upgrade_script_file_name, run_upgrade, do_run_postflight_validations,
                                                 postflight_validations_script_file_name, clean_old_deployments,
                                                 clean_old_deployments_script_file_name,
                                                 stop_on_failure, tarball_location, upgrade_status_service):
            if maybe_upgrade_and_postflight_dsf_node(hadr_set.get('main'), extended_node_dict, target_version,
                                                     upgrade_script_file_name, run_upgrade,
                                                     do_run_postflight_validations,
                                                     postflight_validations_script_file_name, clean_old_deployments,
                                                     clean_old_deployments_script_file_name,
                                                     stop_on_failure, tarball_location, upgrade_status_service):
                return True
        else:
            print(f"Upgrade of HADR DR node failed, will not continue to Main if exists.")
    else:
        print(f"Upgrade of HADR Minor node failed, will not continue to DR and Main if exist.")
    return False


def maybe_upgrade_and_postflight_dsf_node(dsf_node, extended_node_dict, target_version,
                                          upgrade_script_file_name, run_upgrade, do_run_postflight_validations,
                                          postflight_validations_script_file_name, clean_old_deployments,
                                          clean_old_deployments_script_file_name,
                                          stop_on_failure, tarball_location, upgrade_status_service):
    if dsf_node is None:
        return True
    dsf_node_id = generate_dsf_node_id(dsf_node)
    extended_node = extended_node_dict[dsf_node_id]
    if run_upgrade:
        upgrade_success_or_skip = maybe_upgrade_dsf_node(extended_node, target_version, upgrade_script_file_name,
                                                         stop_on_failure, tarball_location, upgrade_status_service)
        if not upgrade_success_or_skip:
            return False

    if do_run_postflight_validations:
        postflight_success_or_skip = maybe_run_postflight_validations(extended_node, target_version,
                                                                      postflight_validations_script_file_name,
                                                                      stop_on_failure, upgrade_status_service)
        if not postflight_success_or_skip:
            return False

    if clean_old_deployments:
        # TODO add status support when clean_old_deployments will be supported
        clean_old_deployments_succeeded = run_clean_old_deployments(dsf_node, extended_node.get('dsf_node_name'),
                                                                    clean_old_deployments_script_file_name)
        if not clean_old_deployments_succeeded:
            # In case clean old deployments failed, print a warning without returning false
            print(f"### Warning: Cleaning old deployments failed for {extended_node.get('dsf_node_name')}")

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

    error_message = None
    try:
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
            error_message = script_output
    except Exception as ex:
        print(f"Upgrading {extended_node.get('dsf_node_name')} ### failed ### with exception: {str(ex)}")
        error_message = str(ex)

    if error_message is not None:
        upgrade_status_service.update_upgrade_status(extended_node.get('dsf_node_id'),
                                                     UpgradeStatus.UPGRADE_FAILED, error_message)
        if stop_on_failure:
            raise UpgradeException(f"Upgrading {extended_node.get('dsf_node_name')} ### failed ###")
        else:
            return False

    return True


def run_upgrade_script(dsf_node, target_version, tarball_location, upgrade_script_file_name):
    if _run_dummy_upgrade:
        print(f"Running dummy upgrade script")
        script_file_name = 'dummy_upgrade_script.sh'
    else:
        script_file_name = upgrade_script_file_name
    script_file_path = build_script_file_path(script_file_name)
    script_contents = read_file_contents(script_file_path)

    args = get_upgrade_script_args(target_version, tarball_location)
    script_run_command = build_bash_script_run_command(script_contents, args)
    # print(f"script_run_command: {script_run_command}")

    script_output = run_remote_script(dsf_node, script_contents, script_run_command)

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
    return f"{SONAR_INSTALLATION_S3_PREFIX}/jsonar-{target_version}.tar.gz"


def maybe_run_postflight_validations(extended_node, target_version, script_file_name, stop_on_failure,
                                     upgrade_status_service):
    if upgrade_status_service.should_run_postflight_validations(extended_node.get('dsf_node_id')):
        return run_postflight_validations(extended_node, target_version, script_file_name, stop_on_failure,
                                          upgrade_status_service)
    return True


def run_postflight_validations(extended_node, target_version, script_file_name, stop_on_failure,
                               upgrade_status_service):
    print(f"Running postflight validations for {extended_node.get('dsf_node_name')}")

    error_message = None
    try:
        upgrade_status_service.update_upgrade_status(extended_node.get('dsf_node_id'),
                                                     UpgradeStatus.RUNNING_POSTFLIGHT_VALIDATIONS)
        postflight_validations_result_json = run_postflight_validations_script(extended_node.get('dsf_node'),
                                                                               target_version,
                                                                               extended_node.get('python_location'),
                                                                               script_file_name)
        postflight_validations_result = json.loads(postflight_validations_result_json)
        print(f"Postflight validations result in {extended_node.get('dsf_node_name')} is "
              f"{postflight_validations_result}")

        passed = are_postflight_validations_passed(postflight_validations_result)
        if passed:
            print(f"### Postflight validations passed for {extended_node.get('dsf_node_name')}")
            upgrade_status_service.update_upgrade_status(extended_node.get('dsf_node_id'),
                                                         UpgradeStatus.POSTFLIGHT_VALIDATIONS_SUCCEEDED)
            upgrade_status_service.update_upgrade_status(extended_node.get('dsf_node_id'),
                                                         UpgradeStatus.SUCCEEDED)
        else:
            print(f"### Postflight validations didn't pass for {extended_node.get('dsf_node_name')}")
            error_message = postflight_validations_result
    except Exception as ex:
        print(f"### Postflight validations for {extended_node.get('dsf_node_name')} failed with exception: {str(ex)}")
        error_message = str(ex)

    if error_message is not None:
        upgrade_status_service.update_upgrade_status(extended_node.get('dsf_node_id'),
                                                     UpgradeStatus.POSTFLIGHT_VALIDATIONS_FAILED,
                                                     error_message)
        if stop_on_failure:
            raise UpgradeException(f"Postflight validations didn't pass for {extended_node.get('dsf_node_id')}")
        else:
            return False

    return True


def run_postflight_validations_script(dsf_node, target_version, python_location, script_file_name):
    script_file_path = build_script_file_path(script_file_name)
    script_contents = read_file_contents(script_file_path)
    script_run_command = build_python_script_run_command(script_contents, target_version, python_location)
    # print(f"script_run_command: {script_run_command}")

    script_output = run_remote_script(dsf_node, script_contents, script_run_command)
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
    script_file_path = build_script_file_path(script_file_name)
    script_contents = read_file_contents(script_file_path)

    script_run_command = build_bash_script_run_command(script_contents)
    # print(f"script_run_command: {script_run_command}")

    script_output = run_remote_script(dsf_node, script_contents, script_run_command)

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


def verify_successful_run(overall_upgrade_status, args, upgrade_status_service):
    '''
    Verifies if the script run was successful from the applicative point of view.
    For example, if no exceptions were raised but the upgrade failed, the run is considered failed.
    :param overall_upgrade_status: The overall upgrade status provided by the upgrade status service
    :param args: The program arguments which include the configuration options
    :param upgrade_status_service
    :return: True if the run was successful, false otherwise
    '''
    if overall_upgrade_status == OverallUpgradeStatus.FAILED or overall_upgrade_status == OverallUpgradeStatus.UNKNOWN:
        is_successful_run = False
    elif overall_upgrade_status in (OverallUpgradeStatus.SUCCEEDED, OverallUpgradeStatus.SUCCEEDED_WITH_WARNINGS):
        is_successful_run = True
    elif overall_upgrade_status == OverallUpgradeStatus.NOT_STARTED and \
            not args.test_connection and \
            not args.run_preflight_validations and \
            not args.run_upgrade and \
            not args.run_postflight_validations:
        is_successful_run = True
    elif overall_upgrade_status == OverallUpgradeStatus.RUNNING:
        is_successful_run = verify_successful_run_by_configuration_options(args, upgrade_status_service)
    else:
        print("verify_successful_run, unexpected scenario was reached")
        is_successful_run = False

    return is_successful_run


def verify_successful_run_by_configuration_options(args, upgrade_status_service):
    if args.run_postflight_validations:
        is_successful_run = upgrade_status_service.are_nodes_with_upgrade_statuses(
            [UpgradeStatus.POSTFLIGHT_VALIDATIONS_SUCCEEDED,
             UpgradeStatus.SUCCEEDED,
             UpgradeStatus.SUCCEEDED_WITH_WARNINGS])
    elif args.run_upgrade:
        is_successful_run = upgrade_status_service.are_nodes_with_upgrade_statuses(
            [UpgradeStatus.UPGRADE_SUCCEEDED,
             UpgradeStatus.SUCCEEDED,
             UpgradeStatus.SUCCEEDED_WITH_WARNINGS])
    elif args.run_preflight_validations:
        is_successful_run = upgrade_status_service.are_nodes_with_upgrade_statuses(
            [UpgradeStatus.PREFLIGHT_VALIDATIONS_SUCCEEDED,
             UpgradeStatus.SUCCEEDED,
             UpgradeStatus.SUCCEEDED_WITH_WARNINGS])
    elif args.test_connection:
        is_successful_run = upgrade_status_service.are_nodes_with_upgrade_statuses([
            UpgradeStatus.TEST_CONNECTION_SUCCEEDED,
            UpgradeStatus.SUCCEEDED,
            UpgradeStatus.SUCCEEDED_WITH_WARNINGS])
    else:
        print("verify_successful_run_by_configuration_options, unexpected scenario was reached")
        is_successful_run = False

    return is_successful_run


# Preparation functions


def get_argument_parser():
    parser = argparse.ArgumentParser(description="Upgrade script for DSF Hub and Agentless Gateway")
    parser.add_argument("--agentless_gws", required=True, help="JSON-encoded Agentless Gateway list")
    parser.add_argument("--dsf_hubs", required=True, help="JSON-encoded DSF Hub list")
    parser.add_argument("--target_version", required=True, help="Target version to upgrade")
    parser.add_argument("--connection_timeout",
                        default=90,
                        help="Client connection timeout in seconds used for the SSH connections between the "
                             "installer machine and the DSF nodes being upgraded. Its purpose is to ensure a "
                             "uniform behavior across different platforms. Note that the SSH server in the DSF nodes "
                             "may have its own timeout configurations which may override this setting.")
    parser.add_argument("--test_connection", type=str_to_bool,
                        default=True,
                        help="Whether to test the SSH connection to all DSF nodes being upgraded "
                             "before starting the upgrade")
    parser.add_argument("--run_preflight_validations", type=str_to_bool,
                        default=True,
                        help="Whether to run preflight validations")
    parser.add_argument("--run_upgrade", type=str_to_bool, default=True, help="Whether to run the upgrade")
    parser.add_argument("--run_postflight_validations", type=str_to_bool,
                        default=True,
                        help="Whether to run postflight validations")
    parser.add_argument("--clean_old_deployments", type=str_to_bool, default=False, help="Whether to clean old deployments")
    parser.add_argument("--stop_on_failure", type=str_to_bool,
                        default=True,
                        help="Whether to stop or continue to upgrade the next DSF nodes in case of failure "
                             "on a DSF node")
    parser.add_argument("--tarball_location",
                        default='{"s3_bucket": "1ef8de27-ed95-40ff-8c08-7969fc1b7901", "s3_region": "us-east-1"}',
                        help="JSON-encoded S3 bucket location of the DSF installation software")
    return parser


def set_global_variables(connection_timeout):
    global _connection_timeout
    _connection_timeout = int(connection_timeout)


if __name__ == "__main__":
    args = get_argument_parser().parse_args()
    set_global_variables(args.connection_timeout)

    main(args)
