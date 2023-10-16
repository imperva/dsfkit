# This file is not in use, it servers as a documentation of the schema of the upgrade state file
{
    "upgrade-statuses": {
        "host1": {
            "status": "Succeeded"
        },
        "1.2.4.3-via-proxy-2.2.2.2": {
            "status": "Running upgrade"
        },
        "1.2.3.6": {
            "status": "Not started"
        },
        "1.2.3.7": {
            "status": "Preflight validations failed",
            "message": "{\"different_version\": false, \"min_version\": true, \"max_version_hop\": true}"
        }
    }
    "target-version": "4.12.0.10.0"
}
