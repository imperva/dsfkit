# DSF Hub and Agentless Gateway Upgrader
[![GitHub tag](https://img.shields.io/github/v/tag/imperva/dsfkit.svg)](https://github.com/imperva/dsfkit/tags)

**Alpha release** 


This Terraform module performs upgrade of DSF Hubs and Agentless Gateways (formerly Sonar).

It performs validations, provides flow management and the ability to run bulk upgrade. It provides a unified upgrade
log and summary for the upgraded DSF nodes.

It utilizes Python to perform this task.


## Upgrade Options

eDSF Kit provides full flexibility as to what can be upgraded: Only DSF Hubs or only Agentless Gateways or both.
Agenltess Gateway without its Hub, DR without its Main, etc.

It is possible to do a major version upgrade, e.g., from 4.10.0.0.0 to 4.12.0.10.0 or a patch upgrade, e.g., from 4.10.0.0.0 to 4.10.0.1.0.

_target_version_ format in the [main.tf](./main.tf) file must be 5 digits, e.g., 4.12.0.10.0 (4.12 is not supported).

## Upgrade Stages

The upgrade procedure consists of several stages, in the following order:

1. **Test connection**: Verifies that SSH connectivity exists to all the DSF nodes being upgraded.
2. **Preflight validations**: Runs a set of validations on each DSF node being upgraded to verify that it is possible 
and safe to run the upgrade. For more details, refer to [Preflight and Postflight Validations](#preflight-and-postflight-validations). 
3. For each DSF node being upgraded:
   1. **Upgrade**: Runs the Sonar script which performs the software upgrade.
   2. **Postflight Validations**: Runs a set of validations to verify that the upgrade was successful.
4. **Summary**: Prints a summary of the upgrade which includes an overall status and the status of each DSF node.

If during any of these stages an error occurs, the upgrade is aborted by default.
To continue the upgrade upon errors, change the _stop_on_failure_ variable. (Refer to [variables.tf](./variables.tf))

There are some exceptions to the above rule:

- If DR upgrade fails, the Main is not upgraded regardless of the _stop_on_failure_ value.
- If Minor upgrade fails, DR and Main are not upgraded regardless of the _stop_on_failure_ value.

### Preflight and Postflight Validations

Upgrade preflight and postflight validations are planned to be a part of the DSF Hub and Agentless Gateway product, 
and for the eDSF Kit tool to be able to utilize them during the upgrade it runs.

Until that happens, eDSF Kit provides a minimal set of preflight and postflight validations as follows:

**Note**: The source version is the version you are upgrading from.
The target version is the version you are upgrading to.

#### Preflight validations:

1. The source and target versions are different.
2. The source version is 4.10 or higher. (eDSF Kit requirement)
3. The upgrade version hop is 1 or 2, e.g., upgrade from 4.10 to 4.12 is supported, and upgrade from 4.10 to 4.13 is not. (Sonar product requirement)
4. There are at least 20GB of free space in the <installation-directory>/data directory.

#### Postflight validations:

1. After the upgrade, the Sonar software version was changed as expected.


## Upgrade Order

This module ensures a deterministic upgrade order.

As required by the Sonar product, the DSF Hub is upgraded last after the Agentless Gateways. 
(Limitation: This constraint is enforced even if the DSF Hub being upgraded is not federated to the Agentless Gateways being upgraded)

Among the Agentless Gateways, if more than one is specified, the upgrade order is as appears in the [main.tf](./main.tf) file in the _agentless_gws_ list.

Among the DSF Hubs, if more than one is specified, the upgrade order is as appears in the [main.tf](./main.tf) file in the _dsf_hubs_ list.

The upgrade order within an HADR replica set is predefined and cannot be changed by the user - Minor first, DR second and Main last. 
If one is missing, it is skipped.
