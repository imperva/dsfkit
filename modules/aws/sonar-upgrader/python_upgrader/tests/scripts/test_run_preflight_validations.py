# test_run_preflight_validations.py

# import pytest
from upgrade.scripts.run_preflight_validations import validate_sonar_version


def test_validate_sonar_version_2_hop():
    # given
    source_version = "4.10.0.0.0"
    target_version = "4.12.0.0.0"

    # when
    higher_target_version, min_version_validation_passed, max_version_hop_validation_passed = \
        validate_sonar_version(source_version, target_version)

    # then
    assert higher_target_version == True
    assert min_version_validation_passed == True
    assert max_version_hop_validation_passed == True


def test_validate_sonar_version_patch():
    # given
    source_version = "4.10.0.0.0"
    target_version = "4.12.0.1.0"

    # when
    higher_target_version, min_version_validation_passed, max_version_hop_validation_passed = \
        validate_sonar_version(source_version, target_version)

    # then
    assert higher_target_version == True
    assert min_version_validation_passed == True
    assert max_version_hop_validation_passed == True


def test_validate_sonar_version_customer1():
    # given
    source_version = "4.10.0.1.3"
    target_version = "4.12.0.0.0"

    # when
    higher_target_version, min_version_validation_passed, max_version_hop_validation_passed = \
        validate_sonar_version(source_version, target_version)

    # then
    assert higher_target_version == True
    assert min_version_validation_passed == True
    assert max_version_hop_validation_passed == True


def test_validate_sonar_version_patch_downgrade():
    # given
    source_version = "4.10.0.1.3"
    target_version = "4.10.0.0.0"

    # when
    higher_target_version, min_version_validation_passed, max_version_hop_validation_passed = \
        validate_sonar_version(source_version, target_version)

    # then
    assert higher_target_version == False
    assert min_version_validation_passed == True
    assert max_version_hop_validation_passed == True


def test_validate_sonar_version_minor_downgrade():
    # given
    source_version = "4.11.0.0.0"
    target_version = "4.10.0.1.0"

    # when
    higher_target_version, min_version_validation_passed, max_version_hop_validation_passed = \
        validate_sonar_version(source_version, target_version)

    # then
    assert higher_target_version == False
    assert min_version_validation_passed == True
    assert max_version_hop_validation_passed == True


def test_validate_sonar_version_from_4_9():
    # given
    source_version = "4.9.c_20221129220420"
    target_version = "4.10.0.1.0"

    # when
    higher_target_version, min_version_validation_passed, max_version_hop_validation_passed = \
        validate_sonar_version(source_version, target_version)

    # then
    assert higher_target_version == True
    assert min_version_validation_passed == False
    assert max_version_hop_validation_passed == True


def test_validate_sonar_version_3_hop():
    # given
    source_version = "4.10.0.0.0"
    target_version = "4.13.0.10.0"

    # when
    higher_target_version, min_version_validation_passed, max_version_hop_validation_passed = \
        validate_sonar_version(source_version, target_version)

    # then
    assert higher_target_version == True
    assert min_version_validation_passed == True
    assert max_version_hop_validation_passed == False


def test_validate_sonar_version_downgrade_and_lower():
    # given
    source_version = "4.9.c_20221129220420"
    target_version = "4.8.0"

    # when
    higher_target_version, min_version_validation_passed, max_version_hop_validation_passed = \
        validate_sonar_version(source_version, target_version)

    # then
    assert higher_target_version == False
    assert min_version_validation_passed == False
    assert max_version_hop_validation_passed == True
