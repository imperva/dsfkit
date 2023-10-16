# run_postflight_validations.py
# Note: This script must not contain an apostrophe, since its contents are wrapped by apostrophes when run
import sys
import json
from datetime import datetime


def main(target_version):
    print("-----------------------------------------------------------------------")
    time = datetime.now().strftime("%a %b %d %H:%M:%S UTC %Y")
    print(f"Running upgrade postlight validations at {time}")
    result = try_validate()
    result_json_string = json.dumps(result)
    # The string "Preflight validations result:" is part of the protocol, if you change it, change its usage
    print(f"Postflight validations result: {result_json_string}")
    print("-----------------------------------------------------------------------")


def try_validate():
    try:
        return validate()
    except Exception as ex:
        print(f"Postflight validations failed with exception: {str(ex)}")
        return {}


def validate():
    actual_version = get_sonar_version()
    correct_version = target_version == actual_version
    result = {
        "correct_version": correct_version
    }
    return result


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


if __name__ == "__main__":
    target_version = sys.argv[1]
    main(target_version)
