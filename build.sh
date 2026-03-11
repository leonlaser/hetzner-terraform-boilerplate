#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKER_DIR="$SCRIPT_DIR/packer"

usage() {
  echo "Usage: $0 <image> [packer-args...]"
  echo ""
  echo "Images:"
  for f in "$PACKER_DIR"/*.pkr.hcl; do
    [ -f "$f" ] && echo "  $(basename "$f" .pkr.hcl)"
  done
  echo ""
  echo "Examples:"
  echo "  $0 base"
  echo "  $0 base -var 'server_type=cx32'"
  exit 1
}

if [[ $# -lt 1 ]]; then
  usage
fi

# Load secrets (same mechanism as tf.sh)
ENV_FILE="$SCRIPT_DIR/env.sh"
if [[ -f "$ENV_FILE" ]]; then
  source "$ENV_FILE"
else
  echo "Error: $ENV_FILE not found." >&2
  echo "Run: cp env.sh.example env.sh" >&2
  exit 1
fi

# Export HCLOUD_TOKEN from Terraform variable
export HCLOUD_TOKEN="${TF_VAR_hcloud_token:?TF_VAR_hcloud_token is not set}"

# Generate image version: date + short git SHA
GIT_SHA="$(git -C "$SCRIPT_DIR" rev-parse --short HEAD 2>/dev/null || echo "unknown")"
IMAGE_VERSION="$(date +%Y%m%d)-${GIT_SHA}"

build_image() {
  local image="$1"
  shift
  local template="$PACKER_DIR/$image.pkr.hcl"

  if [[ ! -f "$template" ]]; then
    echo "Error: template not found: $template" >&2
    exit 1
  fi

  echo "========================================"
  echo "Building image: $image"
  echo "Version:        $IMAGE_VERSION"
  echo "Template:       $template"
  echo "========================================"
  echo ""

  cd "$PACKER_DIR"
  packer init "$template"
  packer build -var "image_version=$IMAGE_VERSION" "$@" "$template"
  echo ""
}

IMAGE="$1"
shift

build_image "$IMAGE" "$@"
