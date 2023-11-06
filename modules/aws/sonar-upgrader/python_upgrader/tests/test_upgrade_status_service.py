# test_upgrade_status_service.py

import pytest
from collections import Counter
from upgrade.upgrade_status_service import UpgradeStatusService, UpgradeStatus, OverallUpgradeStatus
from unittest.mock import ANY  # Import ANY from unittest.mock


@pytest.fixture
def setup_for_each_test():
    upgrade_status_service = UpgradeStatusService()
    yield upgrade_status_service


def test_init_status_when_file_not_exist(setup_for_each_test, mocker):
    # given
    upgrade_status_service = setup_for_each_test
    is_file_exist_mock = mocker.patch('upgrade.upgrade_status_service.is_file_exist', return_value=False)
    read_file_contents_mock = mocker.patch('upgrade.upgrade_status_service.read_file_contents')  # for not_called check
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


def test_init_status_when_file_exists(setup_for_each_test, mocker):
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
    copy_file_mock = mocker.patch('upgrade.upgrade_status_service.copy_file')  # for not_called check

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


def test_init_status_when_file_exists_with_different_target_version(setup_for_each_test, mocker):
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


def test_update_upgrade_status(setup_for_each_test, mocker):
    # given
    upgrade_status_service = setup_for_each_test
    is_file_exist_mock = mocker.patch('upgrade.upgrade_status_service.is_file_exist', return_value=False)
    read_file_contents_mock = mocker.patch('upgrade.upgrade_status_service.read_file_contents')  # for not_called check
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


def test_flush(setup_for_each_test, mocker):
    # given
    upgrade_status_service = setup_for_each_test
    is_file_exist_mock = mocker.patch('upgrade.upgrade_status_service.is_file_exist', return_value=False)
    read_file_contents_mock = mocker.patch('upgrade.upgrade_status_service.read_file_contents')  # for not_called check
    update_file_safely_mock = mocker.patch('upgrade.upgrade_status_service.update_file_safely')

    # when
    upgrade_status_service.init_upgrade_status(["host1", "host2"], "4.12")
    upgrade_status_service.flush()

    # then
    is_file_exist_mock.assert_called_once_with("upgrade_status.json")
    read_file_contents_mock.assert_not_called()
    assert update_file_safely_mock.call_count == 2


@pytest.mark.parametrize("should_method", [
    UpgradeStatusService.should_test_connection,
    UpgradeStatusService.should_collect_python_location,
    UpgradeStatusService.should_run_preflight_validations,
    UpgradeStatusService.should_run_upgrade,
    UpgradeStatusService.should_run_postflight_validations,
])
def test_should_run_step_methods_on_succeeded_status(setup_for_each_test, mocker, should_method):
    # when
    mocker.patch('upgrade.upgrade_status_service.is_file_exist', return_value=False)
    mocker.patch('upgrade.upgrade_status_service.update_file_safely')
    upgrade_status_service = setup_for_each_test
    upgrade_status_service.init_upgrade_status(["host1"], "4.12")
    upgrade_status_service.update_upgrade_status("host1", UpgradeStatus.SUCCEEDED)

    # given
    result = should_method(upgrade_status_service, "host1")

    # then
    assert result is False


def test_get_upgrade_statuses(setup_for_each_test, mocker):
    # when
    mocker.patch('upgrade.upgrade_status_service.is_file_exist', return_value=False)
    mocker.patch('upgrade.upgrade_status_service.update_file_safely')
    upgrade_status_service = setup_for_each_test
    upgrade_status_service.init_upgrade_status(["host1", "host2", "host3", "host4"], "4.12")
    upgrade_status_service.update_upgrade_status("host1", UpgradeStatus.SUCCEEDED)
    upgrade_status_service.update_upgrade_status("host2", UpgradeStatus.SUCCEEDED)
    upgrade_status_service.update_upgrade_status("host3", UpgradeStatus.UPGRADE_FAILED)

    # given
    result = upgrade_status_service.get_upgrade_statuses()

    # then
    # use Counter to ignore order
    assert Counter(result) == Counter([UpgradeStatus.SUCCEEDED, UpgradeStatus.SUCCEEDED,
                                       UpgradeStatus.UPGRADE_FAILED, UpgradeStatus.SUCCEEDED.NOT_STARTED])


@pytest.mark.parametrize("statuses_list, expected_result", [
    ([UpgradeStatus.SUCCEEDED, UpgradeStatus.UPGRADE_FAILED, UpgradeStatus.NOT_STARTED], True),
    ([UpgradeStatus.SUCCEEDED, UpgradeStatus.UPGRADE_FAILED, UpgradeStatus.NOT_STARTED, UpgradeStatus.UPGRADE_SUCCEEDED], True),
    ([UpgradeStatus.SUCCEEDED, UpgradeStatus.UPGRADE_FAILED], False),
])
def test_are_nodes_with_upgrade_statuses(setup_for_each_test, mocker, statuses_list, expected_result):
    # when
    mocker.patch('upgrade.upgrade_status_service.is_file_exist', return_value=False)
    mocker.patch('upgrade.upgrade_status_service.update_file_safely')
    upgrade_status_service = setup_for_each_test
    upgrade_status_service.init_upgrade_status(["host1", "host2", "host3"], "4.12")
    upgrade_status_service.update_upgrade_status("host1", UpgradeStatus.SUCCEEDED)
    upgrade_status_service.update_upgrade_status("host2", UpgradeStatus.NOT_STARTED)
    upgrade_status_service.update_upgrade_status("host3", UpgradeStatus.UPGRADE_FAILED)

    # given
    result = upgrade_status_service.are_nodes_with_upgrade_statuses(statuses_list)

    # then
    assert result == expected_result


@pytest.mark.parametrize("statuses_list, expected_overall_upgrade_status", [
    ([UpgradeStatus.NOT_STARTED, UpgradeStatus.NOT_STARTED, UpgradeStatus.NOT_STARTED], OverallUpgradeStatus.NOT_STARTED),
    ([UpgradeStatus.SUCCEEDED, UpgradeStatus.SUCCEEDED, UpgradeStatus.SUCCEEDED], OverallUpgradeStatus.SUCCEEDED),
    ([UpgradeStatus.SUCCEEDED, UpgradeStatus.SUCCEEDED_WITH_WARNINGS, UpgradeStatus.SUCCEEDED], OverallUpgradeStatus.SUCCEEDED_WITH_WARNINGS),
    ([UpgradeStatus.NOT_STARTED, UpgradeStatus.SUCCEEDED, UpgradeStatus.SUCCEEDED], OverallUpgradeStatus.RUNNING),
    ([UpgradeStatus.RUNNING_UPGRADE, UpgradeStatus.SUCCEEDED, UpgradeStatus.SUCCEEDED], OverallUpgradeStatus.RUNNING),
    ([UpgradeStatus.SUCCEEDED, UpgradeStatus.UPGRADE_FAILED, UpgradeStatus.NOT_STARTED], OverallUpgradeStatus.RUNNING),
    ([UpgradeStatus.SUCCEEDED, UpgradeStatus.UPGRADE_FAILED, UpgradeStatus.SUCCEEDED_WITH_WARNINGS], OverallUpgradeStatus.FAILED),
])
def test_get_overall_upgrade_status(setup_for_each_test, mocker, statuses_list, expected_overall_upgrade_status):
    # when
    mocker.patch('upgrade.upgrade_status_service.is_file_exist', return_value=False)
    mocker.patch('upgrade.upgrade_status_service.update_file_safely')
    upgrade_status_service = setup_for_each_test
    upgrade_status_service.init_upgrade_status(["host1", "host2", "host3"], "4.12")
    upgrade_status_service.update_upgrade_status("host1", statuses_list[0])
    upgrade_status_service.update_upgrade_status("host2", statuses_list[1])
    upgrade_status_service.update_upgrade_status("host3", statuses_list[2])

    # given
    result = upgrade_status_service.get_overall_upgrade_status()

    # then
    assert result == expected_overall_upgrade_status


def test_get_summary(setup_for_each_test, mocker):
    # when
    mocker.patch('upgrade.upgrade_status_service.is_file_exist', return_value=False)
    mocker.patch('upgrade.upgrade_status_service.update_file_safely')
    upgrade_status_service = setup_for_each_test
    upgrade_status_service.init_upgrade_status(["host1", "host2"], "4.12")
    upgrade_status_service.update_upgrade_status("host1", UpgradeStatus.TEST_CONNECTION_FAILED, "host1 error")
    upgrade_status_service.update_upgrade_status("host2", UpgradeStatus.UPGRADE_FAILED, "host2 old error")
    upgrade_status_service.update_upgrade_status("host2", UpgradeStatus.UPGRADE_SUCCEEDED)  # empty message

    # given
    summary_result = upgrade_status_service.get_summary()

    # then
    assert "Overall upgrade status:" in summary_result
    assert OverallUpgradeStatus.RUNNING.value in summary_result  # expected overall status
    assert "host1" in summary_result
    assert UpgradeStatus.TEST_CONNECTION_FAILED.value in summary_result
    assert "host1 error" in summary_result
    assert "host2" in summary_result
    assert UpgradeStatus.UPGRADE_SUCCEEDED.value in summary_result
    assert UpgradeStatus.UPGRADE_FAILED.value not in summary_result
    assert "host2 old error" not in summary_result


# def test_1():
#     service = UpgradeStatusService()
#     service.init_upgrade_status(["1.2.3.7", "host2"], "4.13")
#     service.update_upgrade_status("1.2.3.7", UpgradeStatus.PREFLIGHT_VALIDATIONS_SUCCEEDED, "abcd")
#     service.update_upgrade_status("host2", UpgradeStatus.PREFLIGHT_VALIDATIONS_SUCCEEDED)
#     service.flush()
#     print(service.get_summary())
