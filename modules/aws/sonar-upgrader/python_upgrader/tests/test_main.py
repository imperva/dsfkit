# test_main.py

import pytest
import argparse
import json
from upgrade.main import main, set_global_variables, get_argument_parser
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
def args():
    yield get_argument_parser().parse_args([
        '--agentless_gws', '',
        '--dsf_hubs', '',
        '--target_version', '4.13',
    ])


@pytest.fixture
def upgrade_status_service_mock(mocker):
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

    yield upgrade_status_service_mock


@pytest.fixture
def test_connection_mock(mocker):
    yield mocker.patch('upgrade.main.test_connection')


@pytest.fixture
def run_remote_script_mock(mocker):
    yield mocker.patch('upgrade.main.run_remote_script', side_effect=create_mocked_run_remote_script_side_effects())


@pytest.fixture
def collect_node_info_mock(mocker):
    yield mocker.patch('upgrade.main.collect_node_info')


@pytest.fixture(autouse=True)
def setup_for_each_test(mocker, upgrade_status_service_mock, test_connection_mock, run_remote_script_mock,
                        collect_node_info_mock):
    set_global_variables(100)

    mocker.patch('upgrade.main.join_paths', side_effect=lambda arg1, arg2, arg3: arg3)
    mocker.patch('upgrade.main.read_file_contents', side_effect=lambda file_name: file_name + "_content")

    yield


def test_main_all_flags_disabled(args, run_remote_script_mock):
    # given
    setup_custom_args(args, [{"main": gw1}], [{"main": hub1}], False, False, False, False, True)

    # when
    main(args)

    # then
    run_remote_script_mock.assert_not_called()


def test_main_all_flags_enabled(args, test_connection_mock, run_remote_script_mock, collect_node_info_mock):
    # given
    setup_custom_args(args, [{"main": gw1}], [{"main": hub1}], True, True, True, True, True)

    # when
    main(args)

    # then
    assert test_connection_mock.call_count == 2
    call_args_list = run_remote_script_mock.call_args_list
    assert len(call_args_list) == 6
    assert collect_node_info_mock.call_count == 2
    for host in ["host1", "host100"]:
        assert count_remote_calls_with_host_and_script(call_args_list, host, "run_preflight_validations.py") == 1
        assert count_remote_calls_with_host_and_script(call_args_list, host, "upgrade_v4_10.sh") == 1
        assert count_remote_calls_with_host_and_script(call_args_list, host, "run_postflight_validations.py") == 1


def test_main_only_test_connection_enabled(args, test_connection_mock, run_remote_script_mock):
    # given
    setup_custom_args(args, [{"main": gw1}], [{"main": hub1}], True, False, False, False, True)

    # when
    main(args)

    # then
    assert test_connection_mock.call_count == 2
    run_remote_script_mock.assert_not_called()


def test_main_only_preflight_enabled(args, test_connection_mock, run_remote_script_mock, collect_node_info_mock):
    # given
    setup_custom_args(args, [{"main": gw1}], [{"main": hub1}], False, True, False, False, True)

    # when
    main(args)

    # then
    test_connection_mock.assert_not_called()
    call_args_list = run_remote_script_mock.call_args_list
    assert len(call_args_list) == 2
    assert collect_node_info_mock.call_count == 2
    assert count_remote_calls_with_host_and_script(call_args_list, "host1", "run_preflight_validations.py") == 1
    assert count_remote_calls_with_host_and_script(call_args_list, "host100", "run_preflight_validations.py") == 1


def test_main_only_upgrade_enabled(args, test_connection_mock, run_remote_script_mock):
    # given
    setup_custom_args(args, [{"main": gw1}], [{"main": hub1}], False, False, True, False, True)

    # when
    main(args)

    # then
    test_connection_mock.assert_not_called()
    call_args_list = run_remote_script_mock.call_args_list
    assert len(call_args_list) == 2
    assert count_remote_calls_with_host_and_script(call_args_list, "host1", "upgrade_v4_10.sh") == 1
    assert count_remote_calls_with_host_and_script(call_args_list, "host100", "upgrade_v4_10.sh") == 1


def test_main_only_postflight_enabled(args, test_connection_mock, run_remote_script_mock, collect_node_info_mock):
    # given
    setup_custom_args(args, [{"main": gw1}], [{"main": hub1}], False, False, False, True, True)

    # when
    main(args)

    # then
    test_connection_mock.assert_not_called()
    call_args_list = run_remote_script_mock.call_args_list
    assert len(call_args_list) == 2
    assert collect_node_info_mock.call_count == 2
    assert count_remote_calls_with_host_and_script(call_args_list, "host1", "run_postflight_validations.py") == 1
    assert count_remote_calls_with_host_and_script(call_args_list, "host100", "run_postflight_validations.py") == 1


def test_main_custom_tarball(args, test_connection_mock, run_remote_script_mock, collect_node_info_mock):
    # given
    tarball_location = '{"s3_bucket": "my_custom_bucket", "s3_region": "my_custom_region"}'
    setup_custom_args(args, [{"main": gw1}], [], True, True, True, True, True, tarball_location=tarball_location)

    # when
    main(args)

    # then
    assert test_connection_mock.call_count == 1
    call_args_list = run_remote_script_mock.call_args_list
    assert len(call_args_list) == 3
    assert collect_node_info_mock.call_count == 1
    assert count_remote_calls_with_host_and_script(call_args_list, "host1", "run_postflight_validations.py") == 1
    assert count_remote_calls_with_host_and_script(call_args_list, "host1", "upgrade_v4_10.sh") == 1
    assert count_remote_calls_with_host_and_script(call_args_list, "host1", "run_postflight_validations.py") == 1
    assert "my_custom_bucket" in call_args_list[1].args[2]
    assert "my_custom_region" in call_args_list[1].args[2]


def test_main_host_with_proxy(args, run_remote_script_mock, test_connection_mock, collect_node_info_mock):
    # given
    setup_custom_args(args, [{"main": gw3}], [], True, True, True, True, True)

    # when
    main(args)

    # then
    assert test_connection_mock.call_count == 1
    call_args_list = run_remote_script_mock.call_args_list
    assert len(call_args_list) == 3
    assert collect_node_info_mock.call_count == 1
    assert count_remote_calls_with_host_and_script(call_args_list, "host3", "run_postflight_validations.py") == 1
    assert count_remote_calls_with_host_and_script(call_args_list, "host3", "upgrade_v4_10.sh") == 1
    assert count_remote_calls_with_host_and_script(call_args_list, "host3", "run_postflight_validations.py") == 1


def test_main_skip_successful_host(
        args, upgrade_status_service_mock, test_connection_mock,
        run_remote_script_mock, collect_node_info_mock, mocker):
    # given
    setup_custom_args(args, [{"main": gw1}, {"main": gw2}], [], True, True, True, True, True)
    mocker.patch.object(upgrade_status_service_mock, 'should_test_connection', side_effect=lambda host: host == "host2")
    mocker.patch.object(upgrade_status_service_mock, 'should_collect_node_info', side_effect=lambda host: host == "host2")
    mocker.patch.object(upgrade_status_service_mock, 'should_run_preflight_validations', side_effect=lambda host: host == "host2")
    mocker.patch.object(upgrade_status_service_mock, 'should_run_upgrade', side_effect=lambda host: host == "host2")
    mocker.patch.object(upgrade_status_service_mock, 'should_run_postflight_validations', side_effect=lambda host: host == "host2")

    # when
    main(args)

    # then
    assert test_connection_mock.call_count == 1
    call_args_list = run_remote_script_mock.call_args_list
    assert len(call_args_list) == 3
    assert collect_node_info_mock.call_count == 1
    assert count_remote_calls_with_host_and_script(call_args_list, "host2", "run_preflight_validations.py") == 1
    assert count_remote_calls_with_host_and_script(call_args_list, "host2", "upgrade_v4_10.sh") == 1
    assert count_remote_calls_with_host_and_script(call_args_list, "host2", "run_postflight_validations.py") == 1


@pytest.mark.parametrize("preflight_not_pass_hosts, preflight_error_hosts", [
    (["host1"], []),
    ([], ["host1"]),
])
def test_main_preflight_failure_with_stop_on_failure_true(
        args, test_connection_mock, run_remote_script_mock, collect_node_info_mock,
        preflight_not_pass_hosts, preflight_error_hosts):
    # given
    setup_custom_args(args, [{"main": gw1}, {"main": gw2}], [{"main": hub1}], True, True, True, True, True)
    run_remote_script_mock.side_effect = create_mocked_run_remote_script_side_effects(
        preflight_validations_not_pass_hosts=preflight_not_pass_hosts,
        preflight_validations_error_hosts=preflight_error_hosts,
    )

    # when
    main(args)

    # then
    assert test_connection_mock.call_count == 3
    call_args_list = run_remote_script_mock.call_args_list
    assert len(call_args_list) == 1
    assert collect_node_info_mock.call_count == 3
    assert count_remote_calls_with_host_and_script(call_args_list, "host1", "run_preflight_validations.py") == 1


def test_main_upgrade_failure_with_stop_on_failure_true(
        args, test_connection_mock, run_remote_script_mock, collect_node_info_mock):
    # given
    setup_custom_args(args, [{"main": gw1}, {"main": gw2}], [{"main": hub1}], True, True, True, True, True)
    run_remote_script_mock.side_effect = create_mocked_run_remote_script_side_effects(upgrade_error_hosts=["host1"])

    # when
    main(args)

    # then
    assert test_connection_mock.call_count == 3
    call_args_list = run_remote_script_mock.call_args_list
    assert len(call_args_list) == 4
    assert collect_node_info_mock.call_count == 3
    for host in ["host1", "host2", "host100"]:
        assert count_remote_calls_with_host_and_script(call_args_list, host, "run_preflight_validations.py") == 1
    assert count_remote_calls_with_host_and_script(call_args_list, "host1", "upgrade_v4_10.sh") == 1


def test_main_node_info_failure_with_stop_on_failure_false(
        args, upgrade_status_service_mock, test_connection_mock, run_remote_script_mock, collect_node_info_mock, mocker):
    # given
    setup_custom_args(args, [{"main": gw1}, {"main": gw2}], [{"main": hub1}], True, True, True, True, False)
    # fail if host is host1
    collect_node_info_mock.side_effect = (lambda en: not en.get('dsf_node').get('host') == 'host1')
    mocker.patch.object(upgrade_status_service_mock, 'should_run_preflight_validations', side_effect=lambda host: host != "host1")
    mocker.patch.object(upgrade_status_service_mock, 'should_run_upgrade', side_effect=lambda host: host != "host1")
    mocker.patch.object(upgrade_status_service_mock, 'should_run_postflight_validations', side_effect=lambda host: host != "host1")

    # when
    main(args)

    # then
    assert test_connection_mock.call_count == 3
    call_args_list = run_remote_script_mock.call_args_list
    assert len(call_args_list) == 6
    assert collect_node_info_mock.call_count == 3
    for host in ["host2", "host100"]:
        assert count_remote_calls_with_host_and_script(call_args_list, host, "run_preflight_validations.py") == 1
        assert count_remote_calls_with_host_and_script(call_args_list, host, "upgrade_v4_10.sh") == 1
        assert count_remote_calls_with_host_and_script(call_args_list, host, "run_postflight_validations.py") == 1


@pytest.mark.parametrize("preflight_not_pass_hosts, preflight_error_hosts", [
    (["host1"], []),
    ([], ["host1"]),
])
def test_main_preflight_failure_with_stop_on_failure_false(
        args, upgrade_status_service_mock, test_connection_mock, run_remote_script_mock, collect_node_info_mock,
        mocker, preflight_not_pass_hosts, preflight_error_hosts):
    # given
    setup_custom_args(args, [{"main": gw1}, {"main": gw2}], [{"main": hub1}], True, True, True, True, False)
    run_remote_script_mock.side_effect = create_mocked_run_remote_script_side_effects(
        preflight_validations_not_pass_hosts=preflight_not_pass_hosts,
        preflight_validations_error_hosts=preflight_error_hosts,
    )
    mocker.patch.object(upgrade_status_service_mock, 'should_run_upgrade', side_effect=lambda host: host != "host1")
    mocker.patch.object(upgrade_status_service_mock, 'should_run_postflight_validations', side_effect=lambda host: host != "host1")

    # when
    main(args)

    # then
    assert test_connection_mock.call_count == 3
    call_args_list = run_remote_script_mock.call_args_list
    assert len(call_args_list) == 7
    assert collect_node_info_mock.call_count == 3
    for host in ["host1", "host2", "host100"]:
        assert count_remote_calls_with_host_and_script(call_args_list, host, "run_preflight_validations.py") == 1
    for host in ["host2", "host100"]:
        assert count_remote_calls_with_host_and_script(call_args_list, host, "upgrade_v4_10.sh") == 1
        assert count_remote_calls_with_host_and_script(call_args_list, host, "run_postflight_validations.py") == 1


def test_main_hadr_set_successful(args, test_connection_mock, run_remote_script_mock, collect_node_info_mock):
    # given
    setup_custom_args(args, [{"main": gw1, "dr": gw2}], [{"main": hub1, "dr": hub2, "minor": hub3}], True, True, True, True, True)

    # when
    main(args)

    # then
    assert test_connection_mock.call_count == 5
    call_args_list = run_remote_script_mock.call_args_list
    assert len(call_args_list) == 15
    assert collect_node_info_mock.call_count == 5
    for host in ["host1", "host2", "host100", "host101", "host102"]:
        assert count_remote_calls_with_host_and_script(call_args_list, host, "run_preflight_validations.py") == 1
        assert count_remote_calls_with_host_and_script(call_args_list, host, "upgrade_v4_10.sh") == 1
        assert count_remote_calls_with_host_and_script(call_args_list, host, "run_postflight_validations.py") == 1


def test_main_hadr_set_skip_node_after_hadr_upgrade_failure_stop_on_failure_false(
        args, test_connection_mock, run_remote_script_mock, collect_node_info_mock):
    # given
    setup_custom_args(args, [{"main": gw1, "dr": gw2}], [{"main": hub1, "dr": hub2, "minor": hub3}], True, True, True, True, False)
    run_remote_script_mock.side_effect = create_mocked_run_remote_script_side_effects(upgrade_error_hosts=["host2", "host102"])

    # when
    main(args)

    # then
    assert test_connection_mock.call_count == 5
    call_args_list = run_remote_script_mock.call_args_list
    assert len(call_args_list) == 7
    assert collect_node_info_mock.call_count == 5
    for host in ["host1", "host2", "host100", "host101", "host102"]:
        assert count_remote_calls_with_host_and_script(call_args_list, host, "run_preflight_validations.py") == 1
    assert count_remote_calls_with_host_and_script(call_args_list, "host2", "upgrade_v4_10.sh") == 1
    assert count_remote_calls_with_host_and_script(call_args_list, "host102", "upgrade_v4_10.sh") == 1


@pytest.mark.parametrize("postflight_not_pass_hosts, postflight_error_hosts", [
    (["host2", "host102"], []),
    ([], ["host2", "host102"]),
])
def test_main_hadr_set_skip_node_after_hadr_postflight_failure_stop_on_failure_false(
        args, test_connection_mock, run_remote_script_mock, collect_node_info_mock,
        postflight_not_pass_hosts, postflight_error_hosts):
    # given
    setup_custom_args(args, [{"main": gw1, "dr": gw2}], [{"main": hub1, "dr": hub2, "minor": hub3}], True, True, True, True, False)
    run_remote_script_mock.side_effect = create_mocked_run_remote_script_side_effects(
        postflight_validations_not_pass_hosts=postflight_not_pass_hosts,
        postflight_validations_error_hosts=postflight_error_hosts,
    )

    # when
    main(args)

    # then
    assert test_connection_mock.call_count == 5
    call_args_list = run_remote_script_mock.call_args_list
    assert len(call_args_list) == 9
    assert collect_node_info_mock.call_count == 5
    for host in ["host1", "host2", "host100", "host101", "host102"]:
        assert count_remote_calls_with_host_and_script(call_args_list, host, "run_preflight_validations.py") == 1
    assert count_remote_calls_with_host_and_script(call_args_list, "host2", "upgrade_v4_10.sh") == 1
    assert count_remote_calls_with_host_and_script(call_args_list, "host2", "run_preflight_validations.py") == 1
    assert count_remote_calls_with_host_and_script(call_args_list, "host102", "upgrade_v4_10.sh") == 1
    assert count_remote_calls_with_host_and_script(call_args_list, "host102", "run_preflight_validations.py") == 1


@pytest.mark.xfail(raises=UpgradeException)
def test_main_raise_exception_on_overall_status_failed(
        args, upgrade_status_service_mock, test_connection_mock, run_remote_script_mock, collect_node_info_mock, mocker):
    # given
    setup_custom_args(args, [{"main": gw1}], [], True, True, True, True, True)
    run_remote_script_mock.side_effect = create_mocked_run_remote_script_side_effects()
    mocker.patch.object(upgrade_status_service_mock, 'get_overall_upgrade_status', return_value=OverallUpgradeStatus.FAILED)

    # when
    main(args)

    # then
    assert test_connection_mock.call_count == 1
    call_args_list = run_remote_script_mock.call_args_list
    assert len(call_args_list) == 0
    assert collect_node_info_mock.call_count == 1


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


def create_mocked_run_remote_script_side_effects(preflight_validations_not_pass_hosts=None,
                                                 preflight_validations_error_hosts=None,
                                                 upgrade_error_hosts=None,
                                                 postflight_validations_not_pass_hosts=None,
                                                 postflight_validations_error_hosts=None):
    def mocked_run_remote_script(dsf_node, script_contents, script_run_command):
        host = dsf_node.get('host')
        if "run_preflight_validations.py" in script_contents:
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


def count_remote_calls_with_host_and_script(call_args_list, host, script_content):
    return sum(1 for call_args in call_args_list if call_args.args[0].get('host') == host and script_content in call_args.args[2])
