#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <playbook.yml> [ansible-playbook args...]" >&2
  exit 1
fi

# Required on macOS to avoid Objective-C runtime crashes when Ansible forks.
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES

exec "$ROOT_DIR/.venv/bin/ansible-playbook" "${@}"
