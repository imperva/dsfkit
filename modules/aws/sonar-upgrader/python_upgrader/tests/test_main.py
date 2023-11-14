# test_main.py

import pytest
import argparse
import json
from upgrade.main import main, fill_args_defaults, set_global_variables
from upgrade.upgrade_status_service import OverallUpgradeStatus
from upgrade.upgrade_exception import UpgradeException

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

gw3 = {
    "host": "host3",
    "ssh_user": "ec2-user",
    "ssh_private_key_file_path": "/home/ssh_key2.pem",
    "proxy": {
        "host": "host100",
        "ssh_user": "ec2-user",
        "ssh_private_key_file_path": "/home/ssh_key2.pem",
    }
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
    for host in ["host1", "host100"]:
        assert count_remote_calls_with_host_and_script(call_args_list, host, "get_python_location.sh") == 1
        assert count_remote_calls_with_host_and_script(call_args_list, host, "run_preflight_validations.py") == 1
        assert count_remote_calls_with_host_and_script(call_args_list, host, "upgrade_v4_10.sh") == 1
        assert count_remote_calls_with_host_and_script(call_args_list, host, "run_postflight_validations.py") == 1


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
    assert count_remote_calls_with_host_and_script(call_args_list, "host1", "get_python_location.sh") == 1
    assert count_remote_calls_with_host_and_script(call_args_list, "host1", "run_preflight_validations.py") == 1
    assert count_remote_calls_with_host_and_script(call_args_list, "host100", "get_python_location.sh") == 1
    assert count_remote_calls_with_host_and_script(call_args_list, "host100", "run_preflight_validations.py") == 1


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
    assert count_remote_calls_with_host_and_script(call_args_list, "host1", "upgrade_v4_10.sh") == 1
    assert count_remote_calls_with_host_and_script(call_args_list, "host100", "upgrade_v4_10.sh") == 1


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
    assert count_remote_calls_with_host_and_script(call_args_list, "host1", "get_python_location.sh") == 1
    assert count_remote_calls_with_host_and_script(call_args_list, "host1", "run_postflight_validations.py") == 1
    assert count_remote_calls_with_host_and_script(call_args_list, "host100", "get_python_location.sh") == 1
    assert count_remote_calls_with_host_and_script(call_args_list, "host100", "run_postflight_validations.py") == 1


def test_main_custom_tarball(setup_for_each_test, mocker):
    # given
    args, _, test_connection_mock = setup_for_each_test
    tarball_location = '{"s3_bucket": "my_custom_bucket", "s3_region": "my_custom_region"}'
    setup_custom_args(args, [{"main": gw1}], [], True, True, True, True, True, tarball_location=tarball_location)
    run_remote_script_mock = mocker.patch('upgrade.main.run_remote_script',
                                          side_effect=create_mocked_run_remote_script_side_effects())

    # when
    main(args)

    # then
    assert test_connection_mock.call_count == 1
    call_args_list = run_remote_script_mock.call_args_list
    assert len(call_args_list) == 4
    assert count_remote_calls_with_host_and_script(call_args_list, "host1", "get_python_location.sh") == 1
    assert count_remote_calls_with_host_and_script(call_args_list, "host1", "run_postflight_validations.py") == 1
    assert count_remote_calls_with_host_and_script(call_args_list, "host1", "upgrade_v4_10.sh") == 1
    assert count_remote_calls_with_host_and_script(call_args_list, "host1", "run_postflight_validations.py") == 1
    assert "my_custom_bucket" in call_args_list[2].args[4]
    assert "my_custom_region" in call_args_list[2].args[4]


def test_main_host_with_proxy(setup_for_each_test, mocker):
    # given
    args, _, test_connection_mock = setup_for_each_test
    setup_custom_args(args, [{"main": gw3}], [], True, True, True, True, True)
    test_connection_via_proxy_mock = mocker.patch('upgrade.main.test_connection_via_proxy')
    run_remote_script_via_proxy_mock = mocker.patch('upgrade.main.run_remote_script_via_proxy',
                                          side_effect=create_mocked_run_remote_script_with_proxy_side_effects())

    # when
    main(args)

    # then
    assert test_connection_via_proxy_mock.call_count == 1
    call_args_list = run_remote_script_via_proxy_mock.call_args_list
    assert len(call_args_list) == 4
    assert count_remote_calls_with_host_and_script(call_args_list, "host3", "get_python_location.sh") == 1
    assert count_remote_calls_with_host_and_script(call_args_list, "host3", "run_postflight_validations.py") == 1
    assert count_remote_calls_with_host_and_script(call_args_list, "host3", "upgrade_v4_10.sh") == 1
    assert count_remote_calls_with_host_and_script(call_args_list, "host3", "run_postflight_validations.py") == 1


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
    assert count_remote_calls_with_host_and_script(call_args_list, "host2", "get_python_location.sh") == 1
    assert count_remote_calls_with_host_and_script(call_args_list, "host2", "run_preflight_validations.py") == 1
    assert count_remote_calls_with_host_and_script(call_args_list, "host2", "upgrade_v4_10.sh") == 1
    assert count_remote_calls_with_host_and_script(call_args_list, "host2", "run_postflight_validations.py") == 1


@pytest.mark.parametrize("preflight_not_pass_hosts, preflight_error_hosts", [
    (["host1"], []),
    ([], ["host1"]),
])
def test_main_preflight_failure_with_stop_on_failure_true(setup_for_each_test, mocker,
                                                          preflight_not_pass_hosts, preflight_error_hosts):
    # given
    args, upgrade_status_service_mock, test_connection_mock = setup_for_each_test
    setup_custom_args(args, [{"main": gw1}, {"main": gw2}], [{"main": hub1}], True, True, True, True, True)
    run_remote_script_mock = mocker.patch('upgrade.main.run_remote_script', side_effect=create_mocked_run_remote_script_side_effects(
        preflight_validations_not_pass_hosts=preflight_not_pass_hosts, preflight_validations_error_hosts=preflight_error_hosts))

    # when
    main(args)

    # then
    assert test_connection_mock.call_count == 3
    call_args_list = run_remote_script_mock.call_args_list
    assert len(call_args_list) == 4
    for host in ["host1", "host2", "host100"]:
        assert count_remote_calls_with_host_and_script(call_args_list, host, "get_python_location.sh") == 1
    assert count_remote_calls_with_host_and_script(call_args_list, "host1", "run_preflight_validations.py") == 1


def test_main_upgrade_failure_with_stop_on_failure_true(setup_for_each_test, mocker):
    # given
    args, upgrade_status_service_mock, test_connection_mock = setup_for_each_test
    setup_custom_args(args, [{"main": gw1}, {"main": gw2}], [{"main": hub1}], True, True, True, True, True)
    run_remote_script_mock = mocker.patch('upgrade.main.run_remote_script', side_effect=create_mocked_run_remote_script_side_effects(
        upgrade_error_hosts=["host1"]))

    # when
    main(args)

    # then
    assert test_connection_mock.call_count == 3
    call_args_list = run_remote_script_mock.call_args_list
    assert len(call_args_list) == 7
    for host in ["host1", "host2", "host100"]:
        assert count_remote_calls_with_host_and_script(call_args_list, host, "get_python_location.sh") == 1
        assert count_remote_calls_with_host_and_script(call_args_list, host, "run_preflight_validations.py") == 1
    assert count_remote_calls_with_host_and_script(call_args_list, "host1", "upgrade_v4_10.sh") == 1


def test_main_python_location_failure_with_stop_on_failure_false(setup_for_each_test, mocker):
    # given
    args, upgrade_status_service_mock, test_connection_mock = setup_for_each_test
    setup_custom_args(args, [{"main": gw1}, {"main": gw2}], [{"main": hub1}], True, True, True, True, False)
    run_remote_script_mock = mocker.patch('upgrade.main.run_remote_script', side_effect=create_mocked_run_remote_script_side_effects(
        python_location_error_hosts=["host1"]))
    mocker.patch.object(upgrade_status_service_mock, 'should_run_preflight_validations', side_effect=lambda host: host != "host1")
    mocker.patch.object(upgrade_status_service_mock, 'should_run_upgrade', side_effect=lambda host: host != "host1")
    mocker.patch.object(upgrade_status_service_mock, 'should_run_postflight_validations', side_effect=lambda host: host != "host1")

    # when
    main(args)

    # then
    assert test_connection_mock.call_count == 3
    call_args_list = run_remote_script_mock.call_args_list
    assert len(call_args_list) == 9
    for host in ["host1", "host2", "host100"]:
        assert count_remote_calls_with_host_and_script(call_args_list, host, "get_python_location.sh") == 1
    for host in ["host2", "host100"]:
        assert count_remote_calls_with_host_and_script(call_args_list, host, "run_preflight_validations.py") == 1
        assert count_remote_calls_with_host_and_script(call_args_list, host, "upgrade_v4_10.sh") == 1
        assert count_remote_calls_with_host_and_script(call_args_list, host, "run_postflight_validations.py") == 1


@pytest.mark.parametrize("preflight_not_pass_hosts, preflight_error_hosts", [
    (["host1"], []),
    ([], ["host1"]),
])
def test_main_preflight_failure_with_stop_on_failure_false(setup_for_each_test, mocker,
                                                           preflight_not_pass_hosts, preflight_error_hosts):
    # given
    args, upgrade_status_service_mock, test_connection_mock = setup_for_each_test
    setup_custom_args(args, [{"main": gw1}, {"main": gw2}], [{"main": hub1}], True, True, True, True, False)
    run_remote_script_mock = mocker.patch('upgrade.main.run_remote_script', side_effect=create_mocked_run_remote_script_side_effects(
        preflight_validations_not_pass_hosts=preflight_not_pass_hosts, preflight_validations_error_hosts=preflight_error_hosts))
    mocker.patch.object(upgrade_status_service_mock, 'should_run_upgrade', side_effect=lambda host: host != "host1")
    mocker.patch.object(upgrade_status_service_mock, 'should_run_postflight_validations', side_effect=lambda host: host != "host1")

    # when
    main(args)

    # then
    assert test_connection_mock.call_count == 3
    call_args_list = run_remote_script_mock.call_args_list
    assert len(call_args_list) == 10
    for host in ["host1", "host2", "host100"]:
        assert count_remote_calls_with_host_and_script(call_args_list, host, "get_python_location.sh") == 1
        assert count_remote_calls_with_host_and_script(call_args_list, host, "run_preflight_validations.py") == 1
    for host in ["host2", "host100"]:
        assert count_remote_calls_with_host_and_script(call_args_list, host, "upgrade_v4_10.sh") == 1
        assert count_remote_calls_with_host_and_script(call_args_list, host, "run_postflight_validations.py") == 1


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
        assert count_remote_calls_with_host_and_script(call_args_list, host, "get_python_location.sh") == 1
        assert count_remote_calls_with_host_and_script(call_args_list, host, "run_preflight_validations.py") == 1
        assert count_remote_calls_with_host_and_script(call_args_list, host, "upgrade_v4_10.sh") == 1
        assert count_remote_calls_with_host_and_script(call_args_list, host, "run_postflight_validations.py") == 1


def test_main_hadr_set_skip_node_after_hadr_upgrade_failure_stop_on_failure_false(setup_for_each_test, mocker):
    # given
    args, upgrade_status_service_mock, test_connection_mock = setup_for_each_test
    setup_custom_args(args, [{"main": gw1, "dr": gw2}], [{"main": hub1, "dr": hub2, "minor": hub3}], True, True, True, True, False)
    run_remote_script_mock = mocker.patch('upgrade.main.run_remote_script', side_effect=create_mocked_run_remote_script_side_effects(
        upgrade_error_hosts=["host2", "host102"]))

    # when
    main(args)

    # then
    assert test_connection_mock.call_count == 5
    call_args_list = run_remote_script_mock.call_args_list
    assert len(call_args_list) == 12
    for host in ["host1", "host2", "host100", "host101", "host102"]:
        assert count_remote_calls_with_host_and_script(call_args_list, host, "get_python_location.sh") == 1
        assert count_remote_calls_with_host_and_script(call_args_list, host, "run_preflight_validations.py") == 1
    assert count_remote_calls_with_host_and_script(call_args_list, "host2", "upgrade_v4_10.sh") == 1
    assert count_remote_calls_with_host_and_script(call_args_list, "host102", "upgrade_v4_10.sh") == 1


@pytest.mark.parametrize("postflight_not_pass_hosts, postflight_error_hosts", [
    (["host2", "host102"], []),
    ([], ["host2", "host102"]),
])
def test_main_hadr_set_skip_node_after_hadr_postflight_failure_stop_on_failure_false(setup_for_each_test, mocker,
                                                                                     postflight_not_pass_hosts,
                                                                                     postflight_error_hosts):
    # given
    args, upgrade_status_service_mock, test_connection_mock = setup_for_each_test
    setup_custom_args(args, [{"main": gw1, "dr": gw2}], [{"main": hub1, "dr": hub2, "minor": hub3}], True, True, True, True, False)
    run_remote_script_mock = mocker.patch('upgrade.main.run_remote_script', side_effect=create_mocked_run_remote_script_side_effects(
        postflight_validations_not_pass_hosts=postflight_not_pass_hosts, postflight_validations_error_hosts=postflight_error_hosts))

    # when
    main(args)

    # then
    assert test_connection_mock.call_count == 5
    call_args_list = run_remote_script_mock.call_args_list
    assert len(call_args_list) == 14
    for host in ["host1", "host2", "host100", "host101", "host102"]:
        assert count_remote_calls_with_host_and_script(call_args_list, host, "get_python_location.sh") == 1
        assert count_remote_calls_with_host_and_script(call_args_list, host, "run_preflight_validations.py") == 1
    assert count_remote_calls_with_host_and_script(call_args_list, "host2", "upgrade_v4_10.sh") == 1
    assert count_remote_calls_with_host_and_script(call_args_list, "host2", "run_preflight_validations.py") == 1
    assert count_remote_calls_with_host_and_script(call_args_list, "host102", "upgrade_v4_10.sh") == 1
    assert count_remote_calls_with_host_and_script(call_args_list, "host102", "run_preflight_validations.py") == 1


@pytest.mark.xfail(raises=UpgradeException)
def test_main_raise_exception_on_overall_status_failed(setup_for_each_test, mocker):
    # given
    args, upgrade_status_service_mock, test_connection_mock = setup_for_each_test
    setup_custom_args(args, [{"main": gw1}], [], True, True, True, True, True)
    run_remote_script_mock = mocker.patch('upgrade.main.run_remote_script', side_effect=create_mocked_run_remote_script_side_effects(
        python_location_error_hosts=["host1"]))
    mocker.patch.object(upgrade_status_service_mock, 'get_overall_upgrade_status', return_value=OverallUpgradeStatus.FAILED)

    # when
    main(args)

    # then
    assert test_connection_mock.call_count == 1
    call_args_list = run_remote_script_mock.call_args_list
    assert len(call_args_list) == 1
    assert count_remote_calls_with_host_and_script(call_args_list, "host1", "get_python_location.sh") == 1


def setup_custom_args(args, agentless_gws, dsf_hubs, test_connection, run_preflight_validations, run_upgrade,
                      run_postflight_validations, stop_on_failure, tarball_location=None):
    args.agentless_gws = json.dumps(agentless_gws)
    args.dsf_hubs = json.dumps(dsf_hubs)
    args.test_connection = test_connection
    args.run_preflight_validations = run_preflight_validations
    args.run_upgrade = run_upgrade
    args.run_postflight_validations = run_postflight_validations
    args.stop_on_failure = stop_on_failure
    if tarball_location is not None:
        args.tarball_location = tarball_location


def create_mocked_run_remote_script_side_effects(python_location_error_hosts=None,
                                                 preflight_validations_not_pass_hosts=None,
                                                 preflight_validations_error_hosts=None,
                                                 upgrade_error_hosts=None,
                                                 postflight_validations_not_pass_hosts=None,
                                                 postflight_validations_error_hosts=None):
    def mocked_run_remote_script(host, remote_user, remote_key_filename, script_contents, script_run_command,
                                 connection_timeout):
        if "get_python_location.sh" in script_contents:
            if python_location_error_hosts is not None and host in python_location_error_hosts:
                return "get_python_location error"
            else:
                return "Python location: test_python_location"
        elif "run_preflight_validations.py" in script_contents:
            if preflight_validations_error_hosts is not None and host in preflight_validations_error_hosts:
                return "run_preflight_validations error"
            elif preflight_validations_not_pass_hosts is not None and host in preflight_validations_not_pass_hosts:
                return 'Preflight validations result: {"higher_target_version": true, "min_version": true, ' \
                       '"max_version_hop": true, "enough_free_disk_space": false}'
            else:
                return 'Preflight validations result: {"higher_target_version": true, "min_version": true, ' \
                       '"max_version_hop": true, "enough_free_disk_space": true}'
        elif "upgrade_v4_10.sh" in script_contents:
            if upgrade_error_hosts is not None and host in upgrade_error_hosts:
                return "upgrade error"
            else:
                return "Upgrade completed"
        elif "run_postflight_validations.py" in script_contents:
            if postflight_validations_error_hosts is not None and host in postflight_validations_error_hosts:
                return "run_postflight_validations error"
            elif postflight_validations_not_pass_hosts is not None and host in postflight_validations_not_pass_hosts:
                return 'Postflight validations result: {"correct_version": false}'
            else:
                return 'Postflight validations result: {"correct_version": true}'
        else:
            raise Exception("unknown script")
    return mocked_run_remote_script


def create_mocked_run_remote_script_with_proxy_side_effects():
    mocked_run_remote_script = create_mocked_run_remote_script_side_effects()
    def mocked_run_remote_with_proxy_script(host, remote_user, remote_key_filename, script_contents, script_run_command,
                                            proxy_host, proxy_user, proxy_key_filename, connection_timeout):
        return mocked_run_remote_script(host, remote_user, remote_key_filename, script_contents, script_run_command,
                                        connection_timeout)
    return mocked_run_remote_with_proxy_script


def count_remote_calls_with_host_and_script(call_args_list, host, script_content):
    return sum(1 for call_args in call_args_list if call_args.args[0] == host and script_content in call_args.args[3])
