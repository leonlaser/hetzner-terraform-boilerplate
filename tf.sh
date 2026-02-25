#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENVIRONMENTS_DIR="$SCRIPT_DIR/terraform/environments"

# Auto-discover environments: directories not starting with "_"
VALID_ENVS=()
for dir in "$ENVIRONMENTS_DIR"/*/; do
  name="$(basename "$dir")"
  if [[ "$name" != _* ]]; then
    VALID_ENVS+=("$name")
  fi
done

usage() {
  echo "Usage: $0 <environment> <terraform-command> [args...]"
  echo ""
  echo "Environments: ${VALID_ENVS[*]}"
  echo ""
  echo "Examples:"
  echo "  $0 <environment> init"
  echo "  $0 <environment> plan"
  echo "  $0 <environment> apply"
  echo "  $0 <environment> force-unlock 1234565790"
  exit 1
}

if [[ $# -lt 2 ]]; then
  usage
fi

ENV="$1"
shift
WORK_DIR="$ENVIRONMENTS_DIR/$ENV"

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

# Load secrets (global, then optional per-environment overrides)
ENV_FILE="$SCRIPT_DIR/env.sh"
if [[ -f "$ENV_FILE" ]]; then
  source "$ENV_FILE"
else
  echo "Error: $ENV_FILE not found." >&2
  echo "Run: cp env.sh.example env.sh" >&2
  exit 1
fi

load_env_overrides() {
  local env_file="$ENVIRONMENTS_DIR/$1/env.sh"
  if [[ -f "$env_file" ]]; then
    source "$env_file"
  fi
}
load_env_overrides "$ENV"

COMMAND="$1"
shift

EXTRA_ARGS=()
if [[ "$COMMAND" == "init" ]]; then
  EXTRA_ARGS+=("-backend-config=backend.hcl")
fi

tofu -chdir="$WORK_DIR" "$COMMAND" ${EXTRA_ARGS[@]+"${EXTRA_ARGS[@]}"} "$@"
