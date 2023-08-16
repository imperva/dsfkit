# Agent Gateway Cluster Setup
[![GitHub tag](https://img.shields.io/github/v/tag/imperva/dsfkit.svg)](https://github.com/imperva/dsfkit/tags)

This Terraform module sets up a Gateway Cluster with already provisioned Agent Gateways.

It is assumed that the Agent Gateways which are to a part of the new Cluster were previously 
provisioned in the same Gateway Group.

This module performs the following operations in this order:
1. Creates an empty Cluster
2. Calls an MX API to get all the Agent Gateways in the `gateway_group_name` Gateway Group
3. Moves two Gateways, which are to be the Manager and Backup Manager of the Cluster, from the Gateway Group to the Cluster
4. Activates the Cluster
5. Waits until the Cluster status becomes 'active'
6. Moves the rest of the Agent Gateways to the Cluster
7. Deletes the now obsolete Gateway Group (depending on input)

## Requirements
* [Terraform version](versions.tf)

## Inputs

The following input variables are **required**:

* `cluster_name`: The name of the Cluster to set up
* `gateway_group_name`: The name of the Gateway Group which holds the Agent Gateways to add to the new Cluster. There must be at least 2 Agent Gateways in the Gateway Group, which is the minimum number required to set up a Cluster.
* `mx_details`: Details of the MX for API calls

Refer to [variables.tf](variables.tf) for additional variables with default values and additional info.

## Outputs

Refer to [outputs](outputs.tf) or https://registry.terraform.io/modules/imperva/dsf-agent-gw-cluster-creation/null/latest?tab=outputs
