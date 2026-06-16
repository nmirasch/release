#!/usr/bin/env bash
# Populate the pnpm content-addressable store from Hermeto generic-prefetched tarballs.
# Expects Cachi2 output mounted at /cachi2/output (Konflux hermetic builds).
set -euo pipefail

GENERIC_DIR="${1:-/cachi2/output/deps/generic}"
PNPM_STORE="${PNPM_STORE:-/tmp/pnpm-store}"

mkdir -p "${PNPM_STORE}"
pnpm config set store-dir "${PNPM_STORE}"

shopt -s nullglob
ui_tarballs=("${GENERIC_DIR}"/argocd-ui-*.tgz)
if ((${#ui_tarballs[@]} == 0)); then
  echo "warning: no argocd-ui-*.tgz artifacts found under ${GENERIC_DIR}" >&2
  exit 0
fi

for tarball in "${ui_tarballs[@]}"; do
  pnpm store add "${tarball}" >/dev/null
done

echo "Seeded pnpm store with ${#ui_tarballs[@]} tarballs"
