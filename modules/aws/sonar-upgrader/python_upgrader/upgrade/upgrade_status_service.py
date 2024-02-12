# upgrade_status_service.py

import time

from .utils.utils import format_dictionary_to_json_string, format_string_to_json, value_to_enum
from .utils.file_utils import read_file_contents, update_file_safely, copy_file, is_file_exist
from enum import Enum


class UpgradeStatusService:

    # If you change this value, also change it in .gitignore
    UPGRADE_STATUS_FILE_NAME = "upgrade_status.json"

    def __init__(self):
        self.status_dictionary = {}
        self.target_version = None
        # in case of write file failure, there won't be automatic status updates and manual flush() will be required
        self.write_initial_status_file_error = False

    def init_upgrade_status(self, dsf_node_ids, target_version):
        '''
        Initializes the upgrade status for a list of DSF nodes being upgraded.
        If this is a rerun or gradual upgrade, updates the existing upgrade status, this may mean removing nodes which
        don't exist in the current list of DSF nodes.
        This is considered a rerun or gradual upgrade if a status file exists in which the target version equals
        a certain target version.
        If a status file exists in which the target version is different, the status file is copied aside and a new
        status file is created.
        :param dsf_node_ids: The list of DSF nodes being upgraded
        @:param target_version The target version to upgrade to
        '''
        # Read status file if exists
        exist_upgrade_status_json = None
        try:
            if self._is_status_file_exist():
                print(f"Upgrade status file was found")
                exist_upgrade_status_json = self._read_upgrade_status_as_json()
                print(f"The upgrade status file was read successfully")
            else:
                print(f"Upgrade status file was not found")
        except Exception as ex:
            print(f"Assuming the upgrade status file doesn't exist due to a read file failure with an exception: {str(ex)}")

        exist_dsf_node_status = {}
        if exist_upgrade_status_json:
            exist_target_version = exist_upgrade_status_json.get("target-version")
            if exist_target_version is None or exist_target_version != target_version:
                # new target version
                print(f"New target version was detected: {target_version} (old target version: {exist_target_version})")
                self._backup_status_file()
            else:
                # rerun or gradual upgrade (same version)
                print(f"Same target version was detected: {target_version}")
                exist_dsf_node_status = exist_upgrade_status_json.get("upgrade-statuses", {})

        initial_new_upgrade_status = self._calc_initial_upgrade_status(exist_dsf_node_status, dsf_node_ids)
        self.status_dictionary = initial_new_upgrade_status
        self.target_version = target_version

        # Write to the status file the initial status
        success = self.flush()
        if not success:
            self.write_initial_status_file_error = True

    def get_upgrade_status(self, dsf_node_id):
        '''
        :param dsf_node_id: Id of the DSF node which upgrade status to get
        :return: not-started, running, succeeded, succeeded-with-warnings or failed
        '''
        # assume dsf_node_id in the map, since all nodes were supposed to be added on init_upgrade_status method call
        return self.status_dictionary.get(dsf_node_id).get('status')

    def get_upgrade_statuses(self):
        '''
        Retrieves the upgrade statuses of all the nodes
        :return: a lit list of upgrade statuses
        '''
        return [obj.get('status') for obj in self.status_dictionary.values()]

    def update_upgrade_status(self, dsf_node_id, upgrade_status, message="", flush=True):
        '''
        Updates the upgrade status of a DSF node in the status file
        :param dsf_node_id: Id of the DSF node which status to update
        :param upgrade_status: The upgrade status to update with
        :param message: An optional error/warning/info message
        :param flush: Whether to write to the upgrade status file on disk or not
        '''
        old_status = self.get_upgrade_status(dsf_node_id)
        self.status_dictionary.get(dsf_node_id)['status'] = upgrade_status
        if message is None or message == "":
            self.status_dictionary.get(dsf_node_id).pop('message', None)
            print(f"Updated upgrade status of {dsf_node_id} from {old_status} to {upgrade_status}")
        else:
            self.status_dictionary.get(dsf_node_id)['message'] = message
            print(f"Updated upgrade status of {dsf_node_id} from {old_status} to {upgrade_status} with message: {message}")

        if flush and not self.write_initial_status_file_error:
            # no automatic log on flush for not overloading the output logs
            self.flush(print_logs=False)

    def should_test_connection(self, dsf_node_id):
        status = self.get_upgrade_status(dsf_node_id)
        return status not in (
            UpgradeStatus.SUCCEEDED,
            UpgradeStatus.SUCCEEDED_WITH_WARNINGS
        )

    def should_gather_facts(self, dsf_node_id):
        status = self.get_upgrade_status(dsf_node_id)
        return status not in (
            UpgradeStatus.SUCCEEDED,
            UpgradeStatus.SUCCEEDED_WITH_WARNINGS,
            UpgradeStatus.TEST_CONNECTION_FAILED
        )

    def should_run_preflight_validations(self, dsf_node_id):
        status = self.get_upgrade_status(dsf_node_id)
        return status not in (
            UpgradeStatus.SUCCEEDED,
            UpgradeStatus.SUCCEEDED_WITH_WARNINGS,
            UpgradeStatus.UPGRADE_SUCCEEDED,
            UpgradeStatus.TEST_CONNECTION_FAILED,
            UpgradeStatus.COLLECT_FACTS_FAILED
        )

    def should_run_upgrade(self, dsf_node_id):
        status = self.get_upgrade_status(dsf_node_id)
        # We are not supposed to attempt upgrade if PREFLIGHT_VALIDATIONS_FAILED
        return status not in (
            UpgradeStatus.SUCCEEDED,
            UpgradeStatus.SUCCEEDED_WITH_WARNINGS,
            UpgradeStatus.UPGRADE_SUCCEEDED,
            UpgradeStatus.TEST_CONNECTION_FAILED,
            UpgradeStatus.COLLECT_FACTS_FAILED,
            UpgradeStatus.PREFLIGHT_VALIDATIONS_FAILED
        )

    def should_run_postflight_validations(self, dsf_node_id):
        status = self.get_upgrade_status(dsf_node_id)
        # TODO consider allowing running postflight on SUCCEEDED and SUCCEEDED_WITH_WARNINGS
        return status not in (
            UpgradeStatus.SUCCEEDED,
            UpgradeStatus.SUCCEEDED_WITH_WARNINGS,
            UpgradeStatus.TEST_CONNECTION_FAILED,
            UpgradeStatus.COLLECT_FACTS_FAILED,
            UpgradeStatus.PREFLIGHT_VALIDATIONS_FAILED,
            UpgradeStatus.UPGRADE_FAILED
        )

    def flush(self, print_logs=True):
        '''
        Writes the upgrade status to the file on disk.
        :return: True if successful, false otherwise
        '''
        try:
            self._update_status_file(self.status_dictionary, self.target_version)
            if print_logs:
                print(f"The upgrade status file was updated successfully")
            return True
        except Exception as ex:
            if print_logs:
                print(f"Failed to update to the upgrade status file with an exception: {str(ex)}")
            return False

    def are_nodes_with_upgrade_statuses(self, statuses):
        '''
        Verifies if the upgrade statuses of the nodes equal a specific list of statuses
        :param statuses: The statuses to check against the current nodes statuses
        :return: True if all nodes have specific statuses, false otherwise
        '''
        upgrade_statuses = self.get_upgrade_statuses()
        return all(obj in statuses for obj in upgrade_statuses)

    def get_overall_upgrade_status(self):
        upgrade_statuses = self.get_upgrade_statuses()
        return self._calc_overall_upgrade_status(upgrade_statuses)

    def get_summary(self, overall_upgrade_status=None):
        if overall_upgrade_status is None:
            overall_upgrade_status = self.get_overall_upgrade_status()
        summary = f"Overall upgrade status: {overall_upgrade_status.value}"
        summary += f"\nDSF nodes upgrade statuses:"
        for host in self.status_dictionary.keys():
            padded_host = "{:<45}".format(host)
            optional_message = self.status_dictionary.get(host).get('message')
            summary += f"\n    {padded_host}: {self.status_dictionary.get(host).get('status').value}"
            if optional_message is not None:
                summary += f". Message: {optional_message}"
        return summary

    def _calc_overall_upgrade_status(self, upgrade_statuses):
        '''
        Calculates the overall upgrade status according to the following logic:
        - "Not started" if all nodes are in "Not started" status
        - "Running" if at least one node is running or about to run one of the upgrade stages
        - "Succeeded" if all nodes are in "Succeeded" status
        - "Succeeded with warnings" if at least one node is in "Succeeded with warnings" status, and the rest of
           the nodes (can be 0) are in "Succeeded" status
        -  "Failed" if at least one node failed one of the upgrade stages, and the rest of the nodes (can be 0)
           are "Succeeded" or "Succeeded with warnings"
        Examples:
        - One node is "Test connection succeeded", another node is "Failed" => Overall status is "Running"
        - One node is "Succeeded", another node is "Not started" => Overall status is "Running"
        - One node is "Failed", another node is "Not started" => Overall status is "Running"
        - All nodes are in "Preflight validations succeeded" => Overall status is "Running"
        :return: The overall upgrade status
        '''
        print(f"Calculating overall upgrade status from statuses: {upgrade_statuses}")

        is_not_started = self._is_overall_upgrade_status_not_started(upgrade_statuses)
        is_running = self._is_overall_upgrade_status_running(upgrade_statuses)
        is_succeeded = self._is_overall_upgrade_status_succeeded(upgrade_statuses)
        is_succeeded_with_warnings = self._is_overall_upgrade_status_succeeded_with_warnings(upgrade_statuses)
        is_failed = self._is_overall_upgrade_status_failed(upgrade_statuses)

        return self._get_overall_upgrade_status(is_not_started, is_running, is_succeeded, is_succeeded_with_warnings,
                                                is_failed)

    def _calc_initial_upgrade_status(self, exist_dsf_node_status, dsf_node_ids):
        new_statuses = {node_id: exist_dsf_node_status.get(node_id, {"status": UpgradeStatus.NOT_STARTED})
                        for node_id in dsf_node_ids}
        return new_statuses

    def _is_overall_upgrade_status_not_started(self, statuses):
        '''
        See documentation of calc_overall_upgrade_status()
        '''
        all_count = len(statuses)
        not_started_count = statuses.count(UpgradeStatus.NOT_STARTED)
        return all_count == not_started_count

    def _is_overall_upgrade_status_running(self, statuses):
        '''
        See documentation of calc_overall_upgrade_status()
        '''
        all_count = len(statuses)
        not_started_count = statuses.count(UpgradeStatus.NOT_STARTED)
        running_count = statuses.count(UpgradeStatus.RUNNING_TEST_CONNECTION) \
            + statuses.count(UpgradeStatus.TEST_CONNECTION_SUCCEEDED) \
            + statuses.count(UpgradeStatus.RUNNING_COLLECT_FACTS) \
            + statuses.count(UpgradeStatus.COLLECT_FACTS_SUCCEEDED) \
            + statuses.count(UpgradeStatus.RUNNING_PREFLIGHT_VALIDATIONS) \
            + statuses.count(UpgradeStatus.PREFLIGHT_VALIDATIONS_SUCCEEDED) \
            + statuses.count(UpgradeStatus.RUNNING_UPGRADE) \
            + statuses.count(UpgradeStatus.UPGRADE_SUCCEEDED) \
            + statuses.count(UpgradeStatus.RUNNING_POSTFLIGHT_VALIDATIONS) \
            + statuses.count(UpgradeStatus.POSTFLIGHT_VALIDATIONS_SUCCEEDED)
        is_not_started_treated_as_running = not_started_count > 0 and not_started_count != all_count
        return running_count > 0 or is_not_started_treated_as_running

    def _is_overall_upgrade_status_succeeded(self, statuses):
        '''
        See documentation of calc_overall_upgrade_status()
        '''
        all_count = len(statuses)
        succeeded_count = statuses.count(UpgradeStatus.SUCCEEDED)
        return all_count == succeeded_count

    def _is_overall_upgrade_status_succeeded_with_warnings(self, statuses):
        '''
        See documentation of calc_overall_upgrade_status()
        '''
        all_count = len(statuses)
        succeeded_count = statuses.count(UpgradeStatus.SUCCEEDED)
        succeeded_with_warnings_count = statuses.count(UpgradeStatus.SUCCEEDED_WITH_WARNINGS)
        return succeeded_with_warnings_count > 0 and all_count == (succeeded_count + succeeded_with_warnings_count)

    def _is_overall_upgrade_status_failed(self, statuses):
        '''
        See documentation of calc_overall_upgrade_status()
        '''
        all_count = len(statuses)
        failed_count = statuses.count(UpgradeStatus.UPGRADE_FAILED)
        succeeded_count = statuses.count(UpgradeStatus.SUCCEEDED)
        succeeded_with_warnings_count = statuses.count(UpgradeStatus.SUCCEEDED_WITH_WARNINGS)
        return failed_count > 0 and all_count == (failed_count + succeeded_count + succeeded_with_warnings_count)

    def _get_overall_upgrade_status(self, is_not_started, is_running, is_succeeded, is_succeeded_with_warnings,
                                    is_failed):
        print(f"Getting overall upgrade status based on: is_not_started: {is_not_started}, is_running: {is_running}, "
              f"is_succeeded: {is_succeeded}, is_succeeded_with_warnings: {is_succeeded_with_warnings}, "
              f"is_failed: {is_failed}")
        true_count = sum([is_not_started, is_running, is_succeeded, is_succeeded_with_warnings, is_failed])
        if true_count != 1:
            print(f"Error: Cannot determine the overall upgrade status. Exactly one of is_not_started, "
                  f"is_running, is_succeeded, is_succeeded_with_warnings and is_failed must be true")
            return OverallUpgradeStatus.UNKNOWN
        if is_not_started:
            return OverallUpgradeStatus.NOT_STARTED
        if is_running:
            return OverallUpgradeStatus.RUNNING
        if is_succeeded:
            return OverallUpgradeStatus.SUCCEEDED
        if is_succeeded_with_warnings:
            return OverallUpgradeStatus.SUCCEEDED_WITH_WARNINGS
        if is_failed:
            return OverallUpgradeStatus.FAILED

    def _backup_status_file(self):
        backup_file_name = UpgradeStatusService.UPGRADE_STATUS_FILE_NAME + '.bkp'
        try:
            copy_file(UpgradeStatusService.UPGRADE_STATUS_FILE_NAME, backup_file_name)
            print(f"File '{UpgradeStatusService.UPGRADE_STATUS_FILE_NAME}' copied to '{backup_file_name}' successfully")
        except Exception as ex:
            print(f"Failed to backup file {UpgradeStatusService.UPGRADE_STATUS_FILE_NAME} with an exception: {str(ex)}")

    def _update_status_file(self, initial_new_upgrade_status, target_version):
        timestamp = int(time.time())  # current timestamp with seconds resolution
        content_dict = {
            "upgrade-statuses": initial_new_upgrade_status,
            "target-version": target_version,
            "timestamp": timestamp
        }
        content_json = format_dictionary_to_json_string(content_dict, object_serialize_hook=self._enum_to_json)
        update_file_safely(UpgradeStatusService.UPGRADE_STATUS_FILE_NAME, content_json)
        return UpgradeStatusService.UPGRADE_STATUS_FILE_NAME

    def _read_upgrade_statuses(self):
        upgrade_status = self._read_upgrade_status_as_json()
        return upgrade_status.get("upgrade-statuses")

    def _is_status_file_exist(self):
        return is_file_exist(UpgradeStatusService.UPGRADE_STATUS_FILE_NAME)

    def _read_upgrade_status_as_json(self):
        file_contents = read_file_contents(UpgradeStatusService.UPGRADE_STATUS_FILE_NAME)
        return format_string_to_json(file_contents, self._json_to_enum)

    def _enum_to_json(self, obj):
        if isinstance(obj, Enum):
            return obj.value
        return obj

    def _json_to_enum(self, dct):
        if 'status' in dct:
            matched_enum_key = value_to_enum(UpgradeStatus, dct['status'])
            if matched_enum_key is None:
                raise Exception(f"failed to convert json status \"{dct['status']}\" to UpgradeStatus enum")
            dct['status'] = matched_enum_key
        return dct


class UpgradeStatus(Enum):
    NOT_STARTED = "Not started"
    RUNNING_TEST_CONNECTION = "Running test connection"
    TEST_CONNECTION_FAILED = "Test connection failed"
    TEST_CONNECTION_SUCCEEDED = "Test connection succeeded"
    RUNNING_COLLECT_FACTS = "Running collect facts"
    COLLECT_FACTS_SUCCEEDED = "Collect facts succeeded"
    COLLECT_FACTS_FAILED = "Collect facts failed"
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


class OverallUpgradeStatus(Enum):
    NOT_STARTED = "Not started"
    RUNNING = "In progress"
    SUCCEEDED = "Succeeded"
    SUCCEEDED_WITH_WARNINGS = "Succeeded with warnings"
    FAILED = "Failed"
    UNKNOWN = "Unknown"
