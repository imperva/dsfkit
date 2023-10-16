# upgrade_state_service.py

import time

from utils import update_file_safely, copy_file, format_dictionary_to_json, is_file_exist, read_file_as_json, \
    value_to_enum
from enum import Enum


class UpgradeStateService:

    def __init__(self):
        self.status_dictionary = {}
        self.target_version = None
        # in case of write file failure, there won't be automatic state updates and manual flush() will be required
        self.write_initial_state_file_error = False

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
        # Read state file if exists
        exist_upgrade_status_json = None
        try:
            if self._is_state_file_exist():
                print(f"State file was found")
                exist_upgrade_status_json = self._read_upgrade_state_as_json()
                print(f"The state file was read successfully")
            else:
                print(f"State file was not found")
        except Exception as ex:
            print(f"Assuming the status file doesn't exist due to a read file failure with an exception: {str(ex)}")

        exist_dsf_node_status = {}
        if exist_upgrade_status_json:
            exist_target_version = exist_upgrade_status_json.get("target-version")
            if exist_target_version is None or exist_target_version != target_version:
                # new target version
                print(f"New target version was detected: {target_version} (old target version: {exist_target_version})")
                self._backup_state_file()
            else:
                # rerun or gradual upgrade (same version)
                print(f"Same target version was detected: {target_version}")
                exist_dsf_node_status = exist_upgrade_status_json.get("upgrade-statuses", {})

        initial_new_upgrade_status = self._calc_initial_upgrade_status(exist_dsf_node_status, dsf_node_ids)
        self.status_dictionary = initial_new_upgrade_status
        self.target_version = target_version

        # Write to the state file the initial state
        success = self.flush()
        if not success:
            self.write_initial_state_file_error = True

    def get_upgrade_status(self, dsf_node_id):
        '''
        :param dsf_node_id: Id of the DSF node which upgrade status to get
        :return: not-started, running, succeeded, succeeded-with-warnings or failed
        '''
        # assume dsf_node_id in the map, since all nodes were supposed to be added on init_upgrade_state method call
        return self.status_dictionary.get(dsf_node_id).get('status')

    def get_overall_upgrade_status(self):
        '''
        Calculates the overall upgrade status.
        :return: "Not started" if all nodes are in "Not started" status
                 "Running" if at least one node is running or succeeded in one of the upgrade stages, but not the final stage
                 "Succeeded" if all nodes are in "Succeeded" status
                 "Succeeded with warnings" if all nodes are in "Succeeded with warnings" or "Succeeded" statuses and
                 there is at least one node with "Succeeded with warnings"
                 "Failed" if at least one node failed one of the upgrade stages, and there are no nodes that are
                 still running one of the upgrade stages
        '''
        # TODO implement
        return "Running"

    def update_upgrade_status(self, dsf_node_id, upgrade_status, message="", flush=True):
        '''
        Updates the upgrade status of a DSF node in the state file
        :param dsf_node_id: Id of the DSF node which status to update
        :param upgrade_status: The upgrade status to update with
        :param message: An optional error/warning/info message
        :param flush: Whether to write to the upgrade state file on disk or not
        '''
        old_status = self.get_upgrade_status(dsf_node_id)
        self.status_dictionary.get(dsf_node_id)['status'] = upgrade_status
        if message is None or message == "":
            self.status_dictionary.get(dsf_node_id).pop('message', None)
            print(f"Updated upgrade status of {dsf_node_id} from {old_status} to {upgrade_status}")
        else:
            self.status_dictionary.get(dsf_node_id)['message'] = message
            print(f"Updated upgrade status of {dsf_node_id} from {old_status} to {upgrade_status} with message: {message}")

        if flush and not self.write_initial_state_file_error:
            # no automatic log on flush for not overloading the output logs
            self.flush(print_logs=False)

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

    def flush(self, print_logs=True):
        '''
        Writes the upgrade state to the file on disk.
        :return: True if successful, false otherwise
        '''
        try:
            self._update_state_file(self.status_dictionary, self.target_version)
            if print_logs:
                print(f"The state file was updated successfully")
            return True
        except Exception as ex:
            if print_logs:
                print(f"Failed to update to the state file with an exception: {str(ex)}")
            return False

    def get_summary(self):
        upgrade_statuses = self._get_upgrade_statuses()
        # summary = f"Overall upgrade status: {self.get_overall_upgrade_status()}"
        summary = f"\nDSF nodes upgrade statuses:"
        for host in upgrade_statuses.keys():
            padded_host = "{:<45}".format(host)
            optional_message = upgrade_statuses.get(host).get('message')
            summary += f"\n    {padded_host}: {upgrade_statuses.get(host).get('status')}"
            if optional_message is not None:
                summary += f". Message: {optional_message}"
        return summary

    def _calc_initial_upgrade_status(self, exist_dsf_node_status, dsf_node_ids):
        new_statuses = {node_id: exist_dsf_node_status.get(node_id, {"status": UpgradeState.NOT_STARTED})
                        for node_id in dsf_node_ids}
        return new_statuses

    def _backup_state_file(self):
        file_name = f'upgrade_status.json'
        backup_file_name = file_name + '.bkp'
        copy_file(file_name, backup_file_name)

    def _update_state_file(self, initial_new_upgrade_status, target_version):
        timestamp = int(time.time())  # current timestamp with seconds resolution
        file_name = f'upgrade_status.json'
        content_dict = {
            "upgrade-statuses": initial_new_upgrade_status,
            "target-version": target_version,
            "timestamp": timestamp
        }
        content_json = format_dictionary_to_json(content_dict, object_serialize_hook=self._enum_to_json)
        update_file_safely(file_name, content_json)
        return file_name

    def _get_upgrade_statuses(self):
        upgrade_state = self._read_upgrade_state_as_json()
        return upgrade_state.get("upgrade-statuses")

    def _is_state_file_exist(self):
        return is_file_exist("upgrade_status.json")

    def _read_upgrade_state_as_json(self):
        return read_file_as_json("upgrade_status.json", self._json_to_enum)

    def _enum_to_json(self, obj):
        if isinstance(obj, Enum):
            return obj.value
        return obj

    def _json_to_enum(self, dct):
        if 'status' in dct:
            matched_enum_key = value_to_enum(UpgradeState, dct['status'])
            if matched_enum_key is None:
                raise Exception(f"failed to convert json status \"{dct['status']}\" to UpgradeState enum")
            dct['status'] = matched_enum_key
        return dct


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
    service.init_upgrade_state(["1.2.3.7", "host2"], "4.13")
    service.update_upgrade_status("host2", UpgradeState.RUNNING_COLLECT_PYTHON_LOCATION, "abcd")
    service.update_upgrade_status("host2", UpgradeState.UPGRADE_SUCCEEDED)
    service.flush()
    print(service.get_summary())


if __name__ == "__main__":
    print("UpgradeStateService test")
    test1()
