# upgrade_state_service.py

import time


from utils import create_file, format_json_string, get_file_path, read_file_as_json
from enum import Enum


class UpgradeStateService:

    def __init__(self):
        '''
        Initializes the upgrade state service. For example, creates the state file.
        '''
        self.upgrade_state_file_name = self._create_state_file()

    def get_upgrade_status(self, dsf_node_id):
        '''
        :param dsf_node_id: Id of the DSF node which upgrade status to get
        :return: not-started, running, succeeded, succeeded-with-warnings or failed
        '''
        # TODO
        pass

    def get_overall_upgrade_status(self):
        '''
        Calculates the overall upgrade status.
        :return: not-started if all nodes are in not-started status
                 running if at least one node is in running status
                 succeeded if all nodes are in succeeded status
                 succeeded-with-warnings if all nodes are in succeeded-with-warnings status
                 failed if at least one node is in failed status, and there are no nodes in running status
        '''
        # TODO
        pass

    def update_upgrade_status(self, dsf_node_id, upgrade_status, flush=True):
        '''
        Updates the upgrade status of a DSF node in the state file
        :param dsf_node_id: Id of the DSF node which status to update
        :param upgrade_status: The upgrade status to update with
        :param flush: Whether to write to the upgrade state file on disk or not
        '''
        # TODO
        pass

    def flush(self):
        '''
        Writes the upgrade state to the file on disk.
        :return: True if successful, false otherwise
        '''
        # TODO
        pass

    def pretty_print(self):
        return ""

    def _create_state_file(self):
        timestamp = int(time.time())  # current timestamp with seconds resolution
        file_name = f'upgrade_state_{timestamp}.json'
        contents = format_json_string('{"upgrade-statuses": []}')
        create_file(file_name, contents)
        return file_name

    def _get_upgrade_statuses(self):
        upgrade_state = self._read_upgrade_state_as_json()
        return upgrade_state.get("upgrade-statuses")

    def _read_upgrade_state_as_json(self):
        # TODO not sure the state file will be created in this location
        file_path = get_file_path(self.upgrade_state_file_name)
        return read_file_as_json(file_path)


class UpgradeState(Enum):
    NOT_STARTED = "Not started"
    RUNNING_TEST_CONNECTION = "Running test connection"
    TEST_CONNECTION_FAILED = "Test connection failed"
    TEST_CONNECTION_SUCCEEDED = "Test connection succeeded"
    RUNNING_COLLECT_PYTHON_LOCATION = "Running collect Python location"
    COLLECT_PYTHON_LOCATION_FAILED = "Collect Python location failed"
    RUNNING_PREFLIGHT_VALIDATIONS = "Running preflight validations"
    PREFLIGHT_VALIDATIONS_FAILED = "Preflight validations failed"
    RUNNING_UPGRADE = "Running upgrade"
    UPGRADE_FAILED = "Upgrade failed"
    RUNNING_POSTFLIGHT_VALIDATIONS = "Running postflight validations"
    POSTFLIGHT_VALIDATIONS_FAILED = "Postflight validations failed"
    SUCCEEDED = "Succeeded"
    SUCCEEDED_WITH_WARNINGS = "Succeeded with warnings"


def test1():
    service = UpgradeStateService()


if __name__ == "__main__":
    test1()
