#!/usr/bin/env bash
# Build test for gentoo-OrcaSlicer overlay in a Gentoo container.
# Usage: ./scripts/test-build.sh [--no-cache]

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
IMAGE_NAME="gentoo-orcaslicer-test"
LOG_FILE="${REPO_ROOT}/build.log"

EXTRA_ARGS=()
if [[ "${1:-}" == "--no-cache" ]]; then
    EXTRA_ARGS+=("--no-cache")
fi

# Prefer podman, fall back to docker
if command -v podman &>/dev/null; then
    RUNTIME="podman"
elif command -v docker &>/dev/null; then
    RUNTIME="docker"
else
    echo "ERROR: neither podman nor docker found" >&2
    exit 1
fi

echo "=== Building with ${RUNTIME} ==="
echo "=== Log: ${LOG_FILE} ==="

${RUNTIME} build \
    -f "${REPO_ROOT}/Containerfile" \
    -t "${IMAGE_NAME}" \
    "${EXTRA_ARGS[@]}" \
    "${REPO_ROOT}" 2>&1 | tee "${LOG_FILE}"

EXIT_CODE=${PIPESTATUS[0]}

if [[ ${EXIT_CODE} -eq 0 ]]; then
    echo "=== BUILD SUCCEEDED ==="
else
    echo "=== BUILD FAILED (exit ${EXIT_CODE}) ==="
    echo "Review ${LOG_FILE} for details."
    # Extract last emerge error
    grep -A 20 '^\*\*\* ERROR' "${LOG_FILE}" || true
fi

exit ${EXIT_CODE}
