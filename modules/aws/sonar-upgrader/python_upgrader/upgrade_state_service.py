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

    def init_upgrade_state(self, dsf_node_ids, target_version):
        '''
        Initializes the upgrade state for a list of DSF nodes being upgraded.
        If this is a rerun or gradual upgrade, updates the existing upgrade state, this may mean removing nodes which
        don't exist in the current list of DSF nodes.
        This is considered a rerun or gradual upgrade if a state file exists in which the target version equals
        a certain target version.
        If a state file exists in which the target version is different, the state file is copied aside and a new
        state file is created.
        :param dsf_node_ids: The list of DSF nodes being upgraded
        @:param target_version The target version to upgrade to
        '''
        pass

    def get_upgrade_status(self, dsf_node_id):
        '''
        :param dsf_node_id: Id of the DSF node which upgrade status to get
        :return: not-started, running, succeeded, succeeded-with-warnings or failed
        '''
        # TODO
        return UpgradeState.NOT_STARTED

    def get_overall_upgrade_status(self):
        '''
        Calculates the overall upgrade status.
        :return: "Not started" if all nodes are in "Not started" status
                 "Running" if at least one node is running one of the upgrade stages
                 "Succeeded" if all nodes are in "Succeeded" status
                 "Succeeded with warnings" if all nodes are in "Succeeded with warnings" status
                 "Failed" if at least one node failed one of the upgrade stages, and there are no nodes that are
                 still running one of the upgrade stages
        '''
        # TODO implement
        return {}

    def update_upgrade_status(self, dsf_node_id, upgrade_status, flush=True):
        '''
        Updates the upgrade status of a DSF node in the state file
        :param dsf_node_id: Id of the DSF node which status to update
        :param upgrade_status: The upgrade status to update with
        :param flush: Whether to write to the upgrade state file on disk or not
        '''
        old_status = self.get_upgrade_status(dsf_node_id)
        print(f"Updated upgrade status of {dsf_node_id} from {old_status} to {upgrade_status}")
        # TODO implement

    def should_test_connection(self, dsf_node_id):
        status = self.get_upgrade_status(dsf_node_id)
        return status not in (
            UpgradeState.SUCCEEDED,
            UpgradeState.SUCCEEDED_WITH_WARNINGS
        )

    def should_collect_python_location(self, dsf_node_id):
        status = self.get_upgrade_status(dsf_node_id)
        return status not in (
            UpgradeState.SUCCEEDED,
            UpgradeState.SUCCEEDED_WITH_WARNINGS,
            UpgradeState.TEST_CONNECTION_FAILED
        )

    def should_run_preflight_validations(self, dsf_node_id):
        status = self.get_upgrade_status(dsf_node_id)
        return status not in (
            UpgradeState.SUCCEEDED,
            UpgradeState.SUCCEEDED_WITH_WARNINGS,
            UpgradeState.UPGRADE_SUCCEEDED,
            UpgradeState.TEST_CONNECTION_FAILED,
            UpgradeState.COLLECT_PYTHON_LOCATION_FAILED
        )

    def should_run_upgrade(self, dsf_node_id):
        status = self.get_upgrade_status(dsf_node_id)
        # We are not supposed to attempt upgrade if PREFLIGHT_VALIDATIONS_FAILED
        return status not in (
            UpgradeState.SUCCEEDED,
            UpgradeState.SUCCEEDED_WITH_WARNINGS,
            UpgradeState.UPGRADE_SUCCEEDED,
            UpgradeState.TEST_CONNECTION_FAILED,
            UpgradeState.COLLECT_PYTHON_LOCATION_FAILED,
            UpgradeState.PREFLIGHT_VALIDATIONS_FAILED
        )

    def should_run_postflight_validations(self, dsf_node_id):
        status = self.get_upgrade_status(dsf_node_id)
        # TODO consider allowing running postflight on SUCCEEDED and SUCCEEDED_WITH_WARNINGS
        return status not in (
            UpgradeState.SUCCEEDED,
            UpgradeState.SUCCEEDED_WITH_WARNINGS,
            UpgradeState.TEST_CONNECTION_FAILED,
            UpgradeState.COLLECT_PYTHON_LOCATION_FAILED,
            UpgradeState.PREFLIGHT_VALIDATIONS_FAILED,
            UpgradeState.UPGRADE_FAILED
        )

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
        # TODO should the file have a fixed name?
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
    COLLECT_PYTHON_LOCATION_SUCCEEDED = "Collect Python location succeeded"
    COLLECT_PYTHON_LOCATION_FAILED = "Collect Python location failed"
    RUNNING_PREFLIGHT_VALIDATIONS = "Running preflight validations"
    PREFLIGHT_VALIDATIONS_SUCCEEDED = "Preflight validations succeeded"
    PREFLIGHT_VALIDATIONS_FAILED = "Preflight validations failed"
    RUNNING_UPGRADE = "Running upgrade"
    UPGRADE_FAILED = "Upgrade failed"
    UPGRADE_SUCCEEDED = "Upgrade succeeded"
    RUNNING_POSTFLIGHT_VALIDATIONS = "Running postflight validations"
    POSTFLIGHT_VALIDATIONS_SUCCEEDED = "Postflight validations succeeded"
    POSTFLIGHT_VALIDATIONS_FAILED = "Postflight validations failed"
    SUCCEEDED = "Succeeded"
    SUCCEEDED_WITH_WARNINGS = "Succeeded with warnings"


def test1():
    service = UpgradeStateService()


if __name__ == "__main__":
    test1()
