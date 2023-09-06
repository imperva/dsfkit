# upgrade_state_service.py

import time


from utils import create_file, format_json_string, get_file_path, read_file_as_json


def init():
    '''
    Initializes the upgrade state service. For example, creates the state file.
    :return The upgrade state file name
    '''
    return _create_state_file()


def get_dsf_node_id(dsf_node):
    '''
    :param dsf_node: An Agentless Gateway or DSF Hub
    :return: A unique identifier of the dsf_node within this upgrader
    '''
    # TODO
    pass


def get_upgrade_status(upgrade_state_file_name, dsf_node_id):
    '''
    :param dsf_node_id: id of the DSF node which upgrade status to get
    :param upgrade_state_file_name: The name of the upgrade state file
    :return: not-started, running, succeeded, succeeded-with-warnings or failed
    '''
    # TODO
    pass


def get_overall_upgrade_status(upgrade_state_file_name):
    '''
    Calculates the overall upgrade status.
    :param upgrade_state_file_name: The name of the upgrade state file
    :return: not-started if all nodes are in not-started status
             running if at least one node is in running status
             succeeded if all nodes are in succeeded status
             succeeded-with-warnings if all nodes are in succeeded-with-warnings status
             failed if at least one node is in failed status, and there are no nodes in running status
    '''
    # TODO
    pass


def update_upgrade_status(upgrade_state_file_name, dsf_node, upgrade_status):
    '''
    Updates the upgrade status of a DSF node in the state file
    :param upgrade_state_file_name: The name of the upgrade state file
    :param dsf_node: The DSF node which status to update
    :param upgrade_status: The upgrade status to update with
    '''
    # TODO
    pass


def _create_state_file():
    timestamp = int(time.time()) # current timestamp with seconds resolution
    file_name = f'upgrade_state_{timestamp}.json'
    contents = format_json_string('{"upgrade-statuses": []}')
    create_file(file_name, contents)
    return file_name


def _get_upgrade_statuses(upgrade_state_file_name):
    upgrade_state = _read_upgrade_state_as_json(upgrade_state_file_name)
    return upgrade_state.get("upgrade-statuses")


def _read_upgrade_state_as_json(upgrade_state_file_name):
    # TODO not sure the state file will be created in this location
    file_path = get_file_path(upgrade_state_file_name)
    return read_file_as_json(file_path)


def test1():
    _create_state_file()


if __name__ == "__main__":
    test1()
