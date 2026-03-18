#!/bin/bash
set -euo pipefail

set -a
source "$HOME/.config/borg/env"
set +a

exec borg "$@"
