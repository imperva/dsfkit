# test_upgrade_status_service.py

import pytest
from upgrade.upgrade_status_service import UpgradeStatusService, UpgradeStatus
from unittest.mock import ANY  # Import ANY from unittest.mock


@pytest.fixture
def setup_for_each_test():
    upgrade_status_service = UpgradeStatusService()
    yield upgrade_status_service


def test_init_status_when_file_not_exist(mocker, setup_for_each_test):
    # given
    upgrade_status_service = setup_for_each_test
    is_file_exist_mock = mocker.patch('upgrade.upgrade_status_service.is_file_exist', return_value=False)
    read_file_contents_mock = mocker.patch('upgrade.upgrade_status_service.read_file_contents')
    update_file_safely_mock = mocker.patch('upgrade.upgrade_status_service.update_file_safely')

    # when
    upgrade_status_service.init_upgrade_status(["host1", "host2"], "4.12")

    # then
    host1_status = upgrade_status_service.get_upgrade_status("host1")
    host2_status = upgrade_status_service.get_upgrade_status("host2")
    assert host1_status == UpgradeStatus.NOT_STARTED
    assert host2_status == UpgradeStatus.NOT_STARTED
    is_file_exist_mock.assert_called_once_with("upgrade_status.json")
    read_file_contents_mock.assert_not_called()
    update_file_safely_mock.assert_called_once_with("upgrade_status.json", ANY)


def test_init_status_when_file_exists(mocker, setup_for_each_test):
    # given
    upgrade_status_service = setup_for_each_test
    state_file_content = """
    {
        "upgrade-statuses": {
            "host1": {
                "status": "Succeeded"
            }
        },
        "target-version": "4.12"
    }
    """
    is_file_exist_mock = mocker.patch('upgrade.upgrade_status_service.is_file_exist', return_value=True)
    read_file_contents_mock = mocker.patch('upgrade.upgrade_status_service.read_file_contents',
                                          return_value=state_file_content)
    update_file_safely_mock = mocker.patch('upgrade.upgrade_status_service.update_file_safely')
    copy_file_mock = mocker.patch('upgrade.upgrade_status_service.copy_file')

    # when
    upgrade_status_service.init_upgrade_status(["host1", "host2"], "4.12")

    # then
    host1_status = upgrade_status_service.get_upgrade_status("host1")
    host2_status = upgrade_status_service.get_upgrade_status("host2")
    assert host1_status == UpgradeStatus.SUCCEEDED
    assert host2_status == UpgradeStatus.NOT_STARTED
    is_file_exist_mock.assert_called_once_with("upgrade_status.json")
    read_file_contents_mock.assert_called_once_with("upgrade_status.json")
    update_file_safely_mock.assert_called_once_with("upgrade_status.json", ANY)
    copy_file_mock.assert_not_called()


def test_init_status_when_file_exists_with_different_target_version(mocker, setup_for_each_test):
    # given
    upgrade_status_service = setup_for_each_test
    state_file_content = """
    {
        "upgrade-statuses": {
            "host1": {
                "status": "Succeeded"
            }
        },
        "target-version": "4.12"
    }
    """
    is_file_exist_mock = mocker.patch('upgrade.upgrade_status_service.is_file_exist', return_value=True)
    read_file_contents_mock = mocker.patch('upgrade.upgrade_status_service.read_file_contents',
                                           return_value=state_file_content)
    update_file_safely_mock = mocker.patch('upgrade.upgrade_status_service.update_file_safely')
    copy_file_mock = mocker.patch('upgrade.upgrade_status_service.copy_file')

    # when
    upgrade_status_service.init_upgrade_status(["host1", "host2"], "4.13")

    # then
    host1_status = upgrade_status_service.get_upgrade_status("host1")
    host2_status = upgrade_status_service.get_upgrade_status("host2")
    assert host1_status == UpgradeStatus.NOT_STARTED
    assert host2_status == UpgradeStatus.NOT_STARTED
    is_file_exist_mock.assert_called_once_with("upgrade_status.json")
    read_file_contents_mock.assert_called_once_with("upgrade_status.json")
    update_file_safely_mock.assert_called_once_with(ANY, ANY)
    copy_file_mock.assert_called_once_with("upgrade_status.json", ANY)


def test_update_upgrade_status(mocker, setup_for_each_test):
    # given
    upgrade_status_service = setup_for_each_test
    is_file_exist_mock = mocker.patch('upgrade.upgrade_status_service.is_file_exist', return_value=False)
    read_file_contents_mock = mocker.patch('upgrade.upgrade_status_service.read_file_contents')
    update_file_safely_mock = mocker.patch('upgrade.upgrade_status_service.update_file_safely')

    # when
    upgrade_status_service.init_upgrade_status(["host1", "host2"], "4.12")
    upgrade_status_service.update_upgrade_status("host1", UpgradeStatus.PREFLIGHT_VALIDATIONS_FAILED)

    # then
    host1_status = upgrade_status_service.get_upgrade_status("host1")
    host2_status = upgrade_status_service.get_upgrade_status("host2")
    assert host1_status == UpgradeStatus.PREFLIGHT_VALIDATIONS_FAILED
    assert host2_status == UpgradeStatus.NOT_STARTED
    is_file_exist_mock.assert_called_once_with("upgrade_status.json")
    read_file_contents_mock.assert_not_called()
    assert update_file_safely_mock.call_count == 2


def test_flush(mocker, setup_for_each_test):
    # given
    upgrade_status_service = setup_for_each_test
    is_file_exist_mock = mocker.patch('upgrade.upgrade_status_service.is_file_exist', return_value=False)
    read_file_contents_mock = mocker.patch('upgrade.upgrade_status_service.read_file_contents')
    update_file_safely_mock = mocker.patch('upgrade.upgrade_status_service.update_file_safely')

    # when
    upgrade_status_service.init_upgrade_status(["host1", "host2"], "4.12")
    upgrade_status_service.flush()

    # then
    is_file_exist_mock.assert_called_once_with("upgrade_status.json")
    read_file_contents_mock.assert_not_called()
    assert update_file_safely_mock.call_count == 2
