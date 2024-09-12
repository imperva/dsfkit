# run_preflight_validations.py
# Note: This script must not contain an apostrophe, since its contents are wrapped by apostrophes when run
import sys
import json
from decimal import Decimal
from datetime import datetime
import shutil
from packaging.version import Version, parse


def main(target_version):
    print("---------------------------------------------------------------------")
    time = datetime.now().strftime("%a %b %d %H:%M:%S UTC %Y")
    print(f"Running upgrade preflight validations at {time}")
    result = try_validate()
    result_json_string = json.dumps(result)
    # The string "Preflight validations result:" is part of the protocol, if you change it, change its usage
    print(f"Preflight validations result: {result_json_string}")
    print("---------------------------------------------------------------------")


def try_validate():
    try:
        return validate()
    except Exception as ex:
        print(f"Preflight validations failed with exception: {str(ex)}")
        return {
            "error": str(ex)
        }


def validate():
    source_version, data_dir_path = get_sonar_info()
    higher_target_version, min_version_validation_passed, max_version_hop_validation_passed = \
        validate_sonar_version(source_version, target_version)
    enough_free_disk_space = validate_disk_space(data_dir_path)

    result = {
        "higher_target_version": higher_target_version,
        "min_version": min_version_validation_passed,
        "max_version_hop": max_version_hop_validation_passed,
        "enough_free_disk_space": enough_free_disk_space
    }
    return result


def get_sonar_info():
    jsonar_file_path = "/etc/sysconfig/jsonar"
    version_key = "JSONAR_VERSION="
    data_dir_path_key = "JSONAR_DATADIR="

    version = None
    data_dir_path = None
    
    with open(jsonar_file_path, "r") as file:
        for line in file:
            if version_key in line:
                version = get_value_in_line(line, version_key)
            if data_dir_path_key in line:
                data_dir_path = get_value_in_line(line, data_dir_path_key)

    validate_sonar_version_found(version, jsonar_file_path)
    validate_data_dir_path_found(data_dir_path, jsonar_file_path)
    return version, data_dir_path


def get_value_in_line(line, key):
    return line.split(key, 1)[1].strip()


def validate_sonar_version_found(version, jsonar_file_path):
    if version is not None:
        print(f"Found Sonar version: {version}")
    else:
        raise Exception(f"Sonar version not found in the file {jsonar_file_path}")


def validate_data_dir_path_found(data_dir, jsonar_file_path):
    if data_dir is not None:
        print(f"Found /data directory path: {data_dir}")
    else:
        raise Exception(f"/data directory path not found in the file {jsonar_file_path}")


def validate_sonar_version(source_version, target_version):
    higher_target_version_passed = validate_higher_target_version(source_version, target_version)

    min_version_validation_passed = validate_min_version(source_version)
    max_version_hop_validation_passed = validate_max_version_hop(source_version, target_version)

    if not higher_target_version_passed or not min_version_validation_passed or not max_version_hop_validation_passed:
        print(f"Sonar version validation failed for source version: {source_version} "
              f"and target_version {target_version}")

    return higher_target_version_passed, min_version_validation_passed, max_version_hop_validation_passed


def validate_higher_target_version(source_version, target_version):
    return parse(source_version) < parse(target_version)


# For example, if version is the string "4.12.0.10.0", major is 4 and minor is 12
def validate_min_version(source_version):
    return Version(source_version).major > 4 or \
           (Version(source_version).major == 4 and Version(source_version).minor >= 10)


def validate_max_version_hop(source_version, target_version):
    # TODO handle when 5.x will be released (probably this validation will be removed before then)
    source_version = Version(source_version)
    target_version = Version(target_version)

    if source_version.major == 4 and source_version.minor == 13:
        return True

    hop = target_version.minor - source_version.minor
    print(f"Version hop: {hop}")
    return hop <= 2


def validate_disk_space(data_dir_path):
    required_space_gb = 20

    enough_free_disk_space = check_free_space(data_dir_path, required_space_gb)
    if enough_free_disk_space:
        print(f"There is more than {required_space_gb} GB of free space in {data_dir_path}")
    else:
        print(f"There is not enough free space in {data_dir_path}. Must be {required_space_gb} or more")
    return enough_free_disk_space


def check_free_space(directory, required_space_gb):
    free_space = shutil.disk_usage(directory).free / (2**30)
    print(f"There is {required_space_gb} free space in {directory}")
    return free_space >= required_space_gb


if __name__ == "__main__":
    target_version = sys.argv[1]
    main(target_version)
