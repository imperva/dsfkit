# test_upgrade_status_service.py

import pytest
from upgrade.upgrade_status_service import UpgradeStatusService, UpgradeStatus


@pytest.fixture
def setup_for_each_test():
    upgrade_status_service = UpgradeStatusService()
    yield upgrade_status_service
    # delete state file
    if upgrade_status_service.is_status_file_exist():
        upgrade_status_service.delete_state_file()
        print("State file was deleted successfully")


def test_init_method(setup_for_each_test):
    upgrade_status_service = setup_for_each_test
    upgrade_status_service.init_upgrade_status(["host1"], "4.12")
    host1_status = upgrade_status_service.get_upgrade_status("host1")
    assert host1_status == UpgradeStatus.NOT_STARTED


# def test_failure():
#     assert 5 == 6
