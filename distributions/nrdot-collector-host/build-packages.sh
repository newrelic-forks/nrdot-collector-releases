#!/bin/bash
# Copyright New Relic, Inc. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

# Build packages (deb, rpm, msi) for nrdot-collector-host

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BUILD_DIR="${SCRIPT_DIR}/_build"
DIST_DIR="${SCRIPT_DIR}/dist"
VERSION=$(cd "${SCRIPT_DIR}/../.." && git describe --tags --always)

echo "======================================"
echo "Building nrdot-collector-host packages"
echo "Version: ${VERSION}"
echo "======================================"

# Check if _build directory exists
if [ ! -d "${BUILD_DIR}" ] || [ ! -f "${BUILD_DIR}/main.go" ]; then
    echo "ERROR: Build directory ${BUILD_DIR} does not exist or is missing Go files"
    echo "Please run 'make generate-sources' first to generate the collector code"
    exit 1
fi

# Clean previous dist
rm -rf "${DIST_DIR}"
mkdir -p "${DIST_DIR}"

echo ""
echo "======================================"
echo "Building Linux packages (deb & rpm) using Docker and goreleaser"
echo "======================================"

# Create a Docker image with goreleaser Pro and cross-compilation tools
echo "Building Docker image with goreleaser..."
docker build --load -t nrdot-goreleaser:latest -f - . <<'DOCKERFILE'
FROM golang:1.24-bookworm

# Install build dependencies (no C compiler needed - CGO_ENABLED=0)
RUN apt-get update && apt-get install -y \
    rpm \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install goreleaser Pro
RUN wget -q https://github.com/goreleaser/goreleaser-pro/releases/download/v2.6.1-pro/goreleaser-pro_Linux_x86_64.tar.gz && \
    tar -xzf goreleaser-pro_Linux_x86_64.tar.gz && \
    mv goreleaser /usr/local/bin/ && \
    rm goreleaser-pro_Linux_x86_64.tar.gz

WORKDIR /workspace
DOCKERFILE

# Run goreleaser to build packages
docker run --rm \
    -v "${SCRIPT_DIR}:/workspace" \
    -w /workspace \
    --platform linux/amd64 \
    nrdot-goreleaser:latest \
    bash -c "
        set -e
        goreleaser release --clean --snapshot --skip=publish,sign,validate --config .goreleaser-local.yaml
    "

if [ -d "${DIST_DIR}" ]; then
    echo ""
    echo "✅ Linux packages created:"
    find "${DIST_DIR}" -name "*.deb" -o -name "*.rpm" | while read pkg; do
        echo "   - $(basename $pkg) ($(du -h "$pkg" | cut -f1))"
    done
else
    echo "❌ Build failed"
    exit 1
fi

echo ""
echo "======================================"
echo "Package Build Summary"
echo "======================================"
echo "All packages and binaries are in: ${DIST_DIR}"
echo ""
echo "Linux Packages (deb/rpm):"
find "${DIST_DIR}" -name "*.deb" -o -name "*.rpm" 2>/dev/null | while read pkg; do
    echo "  ✅ $(basename $pkg)"
done || echo "  ⚠️  No Linux packages found"

echo ""
echo "Windows:"
find "${DIST_DIR}" -name "*.zip" -o -name "*.msi" 2>/dev/null | while read pkg; do
    echo "  ✅ $(basename $pkg)"
done || echo "  ⚠️  No Windows packages found"

echo ""
echo "======================================"
echo "Build completed!"
echo "======================================"
