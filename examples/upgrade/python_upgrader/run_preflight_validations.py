# run_preflight_validations.py
# Note: This script must not contain an apostrophe, since its contents are wrapped by apostrophes when run
import sys
import json
from decimal import Decimal

def get_sonar_version():
    jsonar_file_path = "/etc/sysconfig/jsonar"
    target_key = "VERSION="

    version = None
    
    with open(jsonar_file_path, "r") as file:
        for line in file:
            if target_key in line:
                version = line.split(target_key, 1)[1].strip()
                break  # Break once the key is found
    
    if version is not None:
        print("Found Sonar version:", version)
    else:
        print(f"Sonar version not found in the file {jsonar_file_path}")
    return version


# For example, if version is the string "4.12.0.10.0", returns the number 4.12
def extract_major_version(version):
    second_period_index = version.find(".", version.find(".") + 1)
    if second_period_index != -1:
        major_version_str = version[:second_period_index]
        return Decimal(major_version_str)
    else:
        raise Exception(f"Invalid version format: {version}, must be x.x.x.x.x")


def validate_min_version(source_major_version):
    return source_major_version >= 4.10


def validate_max_version_hop(source_major_version, target_major_version):
    # TODO handle when 5.x will be released
    hop = target_major_version - source_major_version
    print(f"Version hop: {hop}")
    return hop <= 0.02


def validate_sonar_version(source_version, target_version):
    same_version = source_version == target_version
    if same_version:
        print("Source and target versions are the same")
        min_version_validation_passed = True
        max_version_hop_validation_passed = True
    else:
        source_major_version = extract_major_version(source_version)
        target_major_version = extract_major_version(target_version)
        min_version_validation_passed = validate_min_version(source_major_version)
        max_version_hop_validation_passed = validate_max_version_hop(source_major_version, target_major_version)

        if not min_version_validation_passed or not max_version_hop_validation_passed:
            print(f"Sonar version validation failed for source version: {source_version} "
                  f"and target_version {target_major_version}")

    return same_version, min_version_validation_passed, max_version_hop_validation_passed


def main(target_version):
    print("********** Running Upgrade Preflight Validations ************")
    source_version = get_sonar_version()
    same_version, min_version_validation_passed, max_version_hop_validation_passed = \
        validate_sonar_version(source_version, target_version)
    result = {
        "same_version": same_version,
        "min_version": min_version_validation_passed, 
        "max_version_hop": max_version_hop_validation_passed
    }
    result_json_string = json.dumps(result)
    # The string "Preflight validations result:" is part of the protocol, if you change it, change its usage
    print(f"Preflight validations result: {result_json_string}")


if __name__ == "__main__":
    target_version = sys.argv[1]
    main(target_version)
