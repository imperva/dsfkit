# test_main.py

import pytest
import argparse
import json
from upgrade.main import main, fill_args_defaults, set_global_variables
from upgrade.upgrade_status_service import OverallUpgradeStatus

gw1 = {
    "host": "host1",
    "ssh_user": "ec2-user",
    "ssh_private_key_file_path": "/home/ssh_key2.pem"
}

gw2 = {
    "host": "host2",
    "ssh_user": "ec2-user",
    "ssh_private_key_file_path": "/home/ssh_key2.pem"
}

hub1 = {
    "host": "host100",
    "ssh_user": "ec2-user",
    "ssh_private_key_file_path": "/home/ssh_key2.pem"
}

hub2 = {
    "host": "host101",
    "ssh_user": "ec2-user",
    "ssh_private_key_file_path": "/home/ssh_key2.pem"
}

hub3 = {
    "host": "host102",
    "ssh_user": "ec2-user",
    "ssh_private_key_file_path": "/home/ssh_key2.pem"
}

@pytest.fixture
def setup_for_each_test(mocker):
    default_args = argparse.Namespace(
        agentless_gws=[],
        dsf_hubs=[],
        target_version="4.13",
        connection_timeout=None,
        test_connection=None,
        run_preflight_validations=None,
        run_upgrade=None,
        run_postflight_validations=None,
        stop_on_failure=None,
        tarball_location=None,
    )
    fill_args_defaults(default_args)
    set_global_variables(100)

    # mock UpgradeStatusService class functions
    upgrade_status_service_mock = mocker.Mock()
    mocker.patch('upgrade.main.UpgradeStatusService', return_value=upgrade_status_service_mock)
    mocker.patch.object(upgrade_status_service_mock, 'should_test_connection', return_value=True)
    mocker.patch.object(upgrade_status_service_mock, 'should_collect_python_location', return_value=True)
    mocker.patch.object(upgrade_status_service_mock, 'should_run_preflight_validations', return_value=True)
    mocker.patch.object(upgrade_status_service_mock, 'should_run_upgrade', return_value=True)
    mocker.patch.object(upgrade_status_service_mock, 'should_run_postflight_validations', return_value=True)
    mocker.patch.object(upgrade_status_service_mock, 'get_summary', return_value="Mock Summary")
    mocker.patch.object(upgrade_status_service_mock, 'are_nodes_with_upgrade_statuses', return_value=True)
    mocker.patch.object(upgrade_status_service_mock, 'get_overall_upgrade_status', return_value=OverallUpgradeStatus.SUCCEEDED)

    mocker.patch('upgrade.main.join_paths', side_effect=lambda arg1, arg2, arg3: arg3)
    mocker.patch('upgrade.main.read_file_contents', side_effect=lambda file_name: file_name + "_content")

    test_connection_mock = mocker.patch('upgrade.main.test_connection')
    mocker.patch('upgrade.main.test_connection_via_proxy')

    yield default_args, upgrade_status_service_mock, test_connection_mock


def test_main_all_flags_disabled(setup_for_each_test, mocker):
    # given
    args, _, _ = setup_for_each_test
    setup_custom_args(args, [{"main": gw1}], [{"main": hub1}], False, False, False, False, True)
    run_remote_script_mock = mocker.patch('upgrade.main.run_remote_script')

    # when
    main(args)

    # then
    run_remote_script_mock.assert_not_called()


def test_main_all_flags_enabled(setup_for_each_test, mocker):
    # given
    args, _, test_connection_mock = setup_for_each_test
    setup_custom_args(args, [{"main": gw1}], [{"main": hub1}], True, True, True, True, True)
    run_remote_script_mock = mocker.patch('upgrade.main.run_remote_script',
                                          side_effect=create_mocked_run_remote_script_side_effects())

    # when
    main(args)

    # then
    assert test_connection_mock.call_count == 2
    call_args_list = run_remote_script_mock.call_args_list
    assert len(call_args_list) == 8
    assert count_calls_with_host_and_script(call_args_list, "host1", "get_python_location.sh") == 1
    assert count_calls_with_host_and_script(call_args_list, "host1", "run_preflight_validations.py") == 1
    assert count_calls_with_host_and_script(call_args_list, "host1", "upgrade_v4_10.sh") == 1
    assert count_calls_with_host_and_script(call_args_list, "host1", "run_postflight_validations.py") == 1
    assert count_calls_with_host_and_script(call_args_list, "host100", "get_python_location.sh") == 1
    assert count_calls_with_host_and_script(call_args_list, "host100", "run_preflight_validations.py") == 1
    assert count_calls_with_host_and_script(call_args_list, "host100", "upgrade_v4_10.sh") == 1
    assert count_calls_with_host_and_script(call_args_list, "host100", "run_postflight_validations.py") == 1


def test_main_only_test_connection_enabled(setup_for_each_test, mocker):
    # given
    args, _, test_connection_mock = setup_for_each_test
    setup_custom_args(args, [{"main": gw1}], [{"main": hub1}], True, False, False, False, True)
    run_remote_script_mock = mocker.patch('upgrade.main.run_remote_script')

    # when
    main(args)

    # then
    assert test_connection_mock.call_count == 2
    run_remote_script_mock.assert_not_called()


def test_main_only_preflight_enabled(setup_for_each_test, mocker):
    # given
    args, _, test_connection_mock = setup_for_each_test
    setup_custom_args(args, [{"main": gw1}], [{"main": hub1}], False, True, False, False, True)
    run_remote_script_mock = mocker.patch('upgrade.main.run_remote_script',
                                          side_effect=create_mocked_run_remote_script_side_effects())

    # when
    main(args)

    # then
    test_connection_mock.assert_not_called()
    call_args_list = run_remote_script_mock.call_args_list
    assert len(call_args_list) == 4
    assert count_calls_with_host_and_script(call_args_list, "host1", "get_python_location.sh") == 1
    assert count_calls_with_host_and_script(call_args_list, "host1", "run_preflight_validations.py") == 1
    assert count_calls_with_host_and_script(call_args_list, "host100", "get_python_location.sh") == 1
    assert count_calls_with_host_and_script(call_args_list, "host100", "run_preflight_validations.py") == 1


def test_main_only_upgrade_enabled(setup_for_each_test, mocker):
    # given
    args, _, test_connection_mock = setup_for_each_test
    setup_custom_args(args, [{"main": gw1}], [{"main": hub1}], False, False, True, False, True)
    run_remote_script_mock = mocker.patch('upgrade.main.run_remote_script',
                                          side_effect=create_mocked_run_remote_script_side_effects())

    # when
    main(args)

    # then
    test_connection_mock.assert_not_called()
    call_args_list = run_remote_script_mock.call_args_list
    assert len(call_args_list) == 2
    assert count_calls_with_host_and_script(call_args_list, "host1", "upgrade_v4_10.sh") == 1
    assert count_calls_with_host_and_script(call_args_list, "host100", "upgrade_v4_10.sh") == 1


def test_main_only_postflight_enabled(setup_for_each_test, mocker):
    # given
    args, _, test_connection_mock = setup_for_each_test
    setup_custom_args(args, [{"main": gw1}], [{"main": hub1}], False, False, False, True, True)
    run_remote_script_mock = mocker.patch('upgrade.main.run_remote_script',
                                          side_effect=create_mocked_run_remote_script_side_effects())

    # when
    main(args)

    # then
    test_connection_mock.assert_not_called()
    call_args_list = run_remote_script_mock.call_args_list
    assert len(call_args_list) == 4
    assert count_calls_with_host_and_script(call_args_list, "host1", "get_python_location.sh") == 1
    assert count_calls_with_host_and_script(call_args_list, "host1", "run_postflight_validations.py") == 1
    assert count_calls_with_host_and_script(call_args_list, "host100", "get_python_location.sh") == 1
    assert count_calls_with_host_and_script(call_args_list, "host100", "run_postflight_validations.py") == 1


def test_main_skip_successful_host(setup_for_each_test, mocker):
    # given
    args, upgrade_status_service_mock, test_connection_mock = setup_for_each_test
    setup_custom_args(args, [{"main": gw1}, {"main": gw2}], [], True, True, True, True, True)
    mocker.patch.object(upgrade_status_service_mock, 'should_test_connection', side_effect=lambda host: host == "host2")
    mocker.patch.object(upgrade_status_service_mock, 'should_collect_python_location', side_effect=lambda host: host == "host2")
    mocker.patch.object(upgrade_status_service_mock, 'should_run_preflight_validations', side_effect=lambda host: host == "host2")
    mocker.patch.object(upgrade_status_service_mock, 'should_run_upgrade', side_effect=lambda host: host == "host2")
    mocker.patch.object(upgrade_status_service_mock, 'should_run_postflight_validations', side_effect=lambda host: host == "host2")
    run_remote_script_mock = mocker.patch('upgrade.main.run_remote_script', side_effect=create_mocked_run_remote_script_side_effects())

    # when
    main(args)

    # then
    assert test_connection_mock.call_count == 1
    call_args_list = run_remote_script_mock.call_args_list
    assert len(call_args_list) == 4
    assert count_calls_with_host_and_script(call_args_list, "host2", "get_python_location.sh") == 1
    assert count_calls_with_host_and_script(call_args_list, "host2", "run_preflight_validations.py") == 1
    assert count_calls_with_host_and_script(call_args_list, "host2", "upgrade_v4_10.sh") == 1
    assert count_calls_with_host_and_script(call_args_list, "host2", "run_postflight_validations.py") == 1


def test_main_hadr_set_successful(setup_for_each_test, mocker):
    # given
    args, upgrade_status_service_mock, test_connection_mock = setup_for_each_test
    setup_custom_args(args, [{"main": gw1, "dr": gw2}], [{"main": hub1, "dr": hub2, "minor": hub3}], True, True, True, True, True)
    run_remote_script_mock = mocker.patch('upgrade.main.run_remote_script', side_effect=create_mocked_run_remote_script_side_effects())

    # when
    main(args)

    # then
    assert test_connection_mock.call_count == 5
    call_args_list = run_remote_script_mock.call_args_list
    assert len(call_args_list) == 20
    for host in ["host1", "host2", "host100", "host101", "host102"]:
        assert count_calls_with_host_and_script(call_args_list, host, "get_python_location.sh") == 1
        assert count_calls_with_host_and_script(call_args_list, host, "run_preflight_validations.py") == 1
        assert count_calls_with_host_and_script(call_args_list, host, "upgrade_v4_10.sh") == 1
        assert count_calls_with_host_and_script(call_args_list, host, "run_postflight_validations.py") == 1


def test_main_hadr_set_skip_node_after_hadr_upgrade_failure(setup_for_each_test, mocker):
    # given
    args, upgrade_status_service_mock, test_connection_mock = setup_for_each_test
    setup_custom_args(args, [{"main": gw1, "dr": gw2}], [{"main": hub1, "dr": hub2, "minor": hub3}], True, True, True, True, False)
    run_remote_script_mock = mocker.patch('upgrade.main.run_remote_script', side_effect=create_mocked_run_remote_script_side_effects(
        upgrade_failure_hosts=["host2", "host102"]))

    # when
    main(args)

    # then
    assert test_connection_mock.call_count == 5
    call_args_list = run_remote_script_mock.call_args_list
    assert len(call_args_list) == 12
    for host in ["host1", "host2", "host100", "host101", "host102"]:
        assert count_calls_with_host_and_script(call_args_list, host, "get_python_location.sh") == 1
        assert count_calls_with_host_and_script(call_args_list, host, "run_preflight_validations.py") == 1
    assert count_calls_with_host_and_script(call_args_list, "host2", "upgrade_v4_10.sh") == 1
    assert count_calls_with_host_and_script(call_args_list, "host102", "upgrade_v4_10.sh") == 1


def test_main_hadr_set_skip_node_after_hadr_postflight_failure(setup_for_each_test, mocker):
    # given
    args, upgrade_status_service_mock, test_connection_mock = setup_for_each_test
    setup_custom_args(args, [{"main": gw1, "dr": gw2}], [{"main": hub1, "dr": hub2, "minor": hub3}], True, True, True, True, False)
    run_remote_script_mock = mocker.patch('upgrade.main.run_remote_script', side_effect=create_mocked_run_remote_script_side_effects(
        postlight_validations_failure_hosts=["host2", "host102"]))

    # when
    main(args)

    # then
    assert test_connection_mock.call_count == 5
    call_args_list = run_remote_script_mock.call_args_list
    assert len(call_args_list) == 14
    for host in ["host1", "host2", "host100", "host101", "host102"]:
        assert count_calls_with_host_and_script(call_args_list, host, "get_python_location.sh") == 1
        assert count_calls_with_host_and_script(call_args_list, host, "run_preflight_validations.py") == 1
    assert count_calls_with_host_and_script(call_args_list, "host2", "upgrade_v4_10.sh") == 1
    assert count_calls_with_host_and_script(call_args_list, "host2", "run_preflight_validations.py") == 1
    assert count_calls_with_host_and_script(call_args_list, "host102", "upgrade_v4_10.sh") == 1
    assert count_calls_with_host_and_script(call_args_list, "host102", "run_preflight_validations.py") == 1


def setup_custom_args(args, agentless_gws, dsf_hubs, test_connection, run_preflight_validations, run_upgrade,
                      run_postflight_validations, stop_on_failure):
    args.agentless_gws = json.dumps(agentless_gws)
    args.dsf_hubs = json.dumps(dsf_hubs)
    args.test_connection = test_connection
    args.run_preflight_validations = run_preflight_validations
    args.run_upgrade = run_upgrade
    args.run_postflight_validations = run_postflight_validations
    args.stop_on_failure = stop_on_failure


def create_mocked_run_remote_script_side_effects(python_location_failure_hosts=None,
                                                 preflight_validations_failure_hosts=None,
                                                 upgrade_failure_hosts=None,
                                                 postlight_validations_failure_hosts=None):
    def mocked_run_remote_script(host, remote_user, remote_key_filename, script_contents, script_run_command,
                                 connection_timeout):
        if "get_python_location.sh" in script_contents:
            if python_location_failure_hosts is None or host not in python_location_failure_hosts:
                return "Python location: test_python_location"
            else:
                return "get_python_location error"
        elif "run_preflight_validations.py" in script_contents:
            if preflight_validations_failure_hosts is None or host not in preflight_validations_failure_hosts:
                return 'Preflight validations result: {"different_version": true, "min_version": true, ' \
                       '"max_version_hop": true, "enough_free_disk_space": true}'
            else:
                return "run_preflight_validations error"
        elif "upgrade_v4_10.sh" in script_contents:
            if upgrade_failure_hosts is None or host not in upgrade_failure_hosts:
                return "Upgrade completed"
            else:
                return "upgrade error"
        elif "run_postflight_validations.py" in script_contents:
            if postlight_validations_failure_hosts is None or host not in postlight_validations_failure_hosts:
                return 'Postflight validations result: {"correct_version": true}'
            else:
                return "run_postflight_validations error"
        else:
            raise Exception("unknown script")
    return mocked_run_remote_script


def count_calls_with_host_and_script(call_args_list, host, script_content):
    return sum(1 for call_args in call_args_list if call_args.args[0] == host and script_content in call_args.args[3])
