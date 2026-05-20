#!/usr/bin/env bash
#
# check_registry_versions.sh — Verify that the Terraform Registry has indexed
# a given dsfkit release tag for every per-module repo.
#
# Background:
# The dsfkit release flow (.github/workflows/release.yml) pushes a new tag
# (e.g. 1.7.35) to ~25 sibling repos under github.com/imperva/terraform-*-dsf-*.
# The Terraform Registry mirrors them via a GitHub webhook. That webhook can
# be delayed or dropped, which is what happened in the 1.7.35 release: the
# code was on GitHub but the registry kept the previous version as the latest.
#
# Usage:
#   scripts/check_registry_versions.sh                # checks the version in main.tf
#   scripts/check_registry_versions.sh 1.7.35         # checks an explicit version
#
# Exit code 0 if every module exposes the expected version on the registry,
# non-zero otherwise (and prints a list of the modules that are still behind
# along with the resync URL to click in the registry UI).

set -euo pipefail

EXPECTED="${1:-}"

if [ -z "$EXPECTED" ]; then
    if [ -f main.tf ] && grep -q 'version = ".*latest release tag' main.tf 2>/dev/null; then
        EXPECTED=$(grep 'latest release tag' main.tf | head -1 | sed -E 's/.*version = "([^"]+)".*/\1/')
    elif [ -f examples/aws/poc/dsf_deployment/main.tf ]; then
        EXPECTED=$(grep 'latest release tag' examples/aws/poc/dsf_deployment/main.tf | head -1 | sed -E 's/.*version = "([^"]+)".*/\1/')
    fi
fi

if [ -z "$EXPECTED" ]; then
    echo "Usage: $0 <version>"
    exit 2
fi

echo "Expected version: $EXPECTED"
echo

# Keep this list in sync with the matrix in .github/workflows/deploy_module.yml
MODULES=(
    # AWS provider
    "imperva/dsf-hub/aws"
    "imperva/dsf-agentless-gw/aws"
    "imperva/dsf-poc-db-onboarder/aws"
    "imperva/dsf-sonar-upgrader/aws"
    "imperva/dsf-mx/aws"
    "imperva/dsf-agent-gw/aws"
    "imperva/dsf-db-with-agent/aws"
    "imperva/dsf-dra-admin/aws"
    "imperva/dsf-dra-analytics/aws"
    "imperva/dsf-ciphertrust-manager/aws"
    "imperva/dsf-cte-ddc-agent/aws"
    "imperva/dsf-globals/aws"
    # Azurerm provider
    "imperva/dsf-hub/azurerm"
    "imperva/dsf-agentless-gw/azurerm"
    "imperva/dsf-poc-db-onboarder/azurerm"
    "imperva/dsf-mx/azurerm"
    "imperva/dsf-agent-gw/azurerm"
    "imperva/dsf-db-with-agent/azurerm"
    "imperva/dsf-dra-admin/azurerm"
    "imperva/dsf-dra-analytics/azurerm"
    "imperva/dsf-globals/azurerm"
    # Null provider
    "imperva/dsf-hadr/null"
    "imperva/dsf-federation/null"
    "imperva/dsf-agent-gw-cluster-setup/null"
    "imperva/dsf-ciphertrust-manager-cluster-setup/null"
)

ok=0
behind=()
for m in "${MODULES[@]}"; do
    versions=$(curl -fsSL "https://registry.terraform.io/v1/modules/${m}/versions" 2>/dev/null | jq -r '.modules[0].versions[].version' 2>/dev/null || true)
    if echo "$versions" | grep -qx "$EXPECTED"; then
        printf "  \xE2\x9C\x93 %s\n" "$m"
        ok=$((ok + 1))
    else
        latest=$(echo "$versions" | sort -V | tail -1)
        printf "  \xE2\x9C\x97 %-55s (latest indexed: %s)\n" "$m" "$latest"
        behind+=("$m")
    fi
done

echo
echo "$ok / ${#MODULES[@]} modules have $EXPECTED indexed."

if [ ${#behind[@]} -gt 0 ]; then
    echo
    echo "To force a resync, open each of these pages in the Terraform Registry"
    echo "(while logged in as the imperva org owner) and click 'Manage Module ->"
    echo "Resync Module':"
    echo
    for m in "${behind[@]}"; do
        echo "  https://registry.terraform.io/modules/${m}"
    done
    exit 1
fi
