#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENVIRONMENTS_DIR="$SCRIPT_DIR/terraform/environments"
VALID_ENVS=("demo" "staging" "production")

# Load secrets
POPULATE_ENV="$SCRIPT_DIR/populate-env.sh"
if [[ -f "$POPULATE_ENV" ]]; then
  # shellcheck source=/dev/null
  source "$POPULATE_ENV"
else
  echo "Error: $POPULATE_ENV not found." >&2
  echo "Run: cp populate-env.sh.example populate-env.sh" >&2
  exit 1
fi

usage() {
  echo "Usage: $0 <environment> <terraform-command> [args...]"
  echo ""
  echo "Environments: ${VALID_ENVS[*]}"
  echo ""
  echo "Examples:"
  echo "  $0 production init"
  echo "  $0 staging plan"
  echo "  $0 demo apply"
  echo "  $0 production plan -target=module.environment.hcloud_server.default"
  exit 1
}

if [[ $# -lt 2 ]]; then
  usage
fi

ENV="$1"
shift

# Validate environment
valid=false
for e in "${VALID_ENVS[@]}"; do
  if [[ "$e" == "$ENV" ]]; then
    valid=true
    break
  fi
done
if [[ "$valid" == false ]]; then
  echo "Error: invalid environment '$ENV'" >&2
  echo "Valid environments: ${VALID_ENVS[*]}" >&2
  exit 1
fi

WORK_DIR="$ENVIRONMENTS_DIR/$ENV"

# Auto-append -backend-config for init
EXTRA_ARGS=()
if [[ "$1" == "init" && -f "$ENVIRONMENTS_DIR/backend.hcl" ]]; then
  EXTRA_ARGS+=("-backend-config=$ENVIRONMENTS_DIR/backend.hcl")
fi

# Global tfvars (applied to all environments)
if [[ -f "$ENVIRONMENTS_DIR/terraform.tfvars" ]]; then
  EXTRA_ARGS+=("-var-file=$ENVIRONMENTS_DIR/terraform.tfvars")
fi

# Environment-specific tfvars (overrides global values)
if [[ -f "$WORK_DIR/terraform.tfvars" ]]; then
  EXTRA_ARGS+=("-var-file=$WORK_DIR/terraform.tfvars")
fi

terraform -chdir="$WORK_DIR" "$@" "${EXTRA_ARGS[@]+"${EXTRA_ARGS[@]}"}"
