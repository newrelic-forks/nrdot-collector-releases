#!/bin/bash
# Copyright New Relic, Inc. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

# Build all binaries for nrdot-collector-host
# This script builds Linux AMD64, Linux ARM64, and Windows AMD64
# CGO_ENABLED=0 (Oracle and SQL Server receivers use pure Go implementations)

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BUILD_DIR="${SCRIPT_DIR}/_build"
OUTPUT_DIR="${SCRIPT_DIR}/binaries"
VERSION=$(cd "${SCRIPT_DIR}/../.." && git describe --tags --always)

echo "======================================"
echo "Building nrdot-collector-host binaries"
echo "Version: ${VERSION}"
echo "======================================"

# Create output directory
mkdir -p "${OUTPUT_DIR}"

# Check if _build directory exists and has Go files
if [ ! -d "${BUILD_DIR}" ] || [ ! -f "${BUILD_DIR}/main.go" ]; then
    echo "ERROR: Build directory ${BUILD_DIR} does not exist or is missing Go files"
    echo "Please run 'make generate-sources' first to generate the collector code"
    exit 1
fi

# Build Linux AMD64 using Docker
echo ""
echo "======================================"
echo "Building Linux AMD64"
echo "======================================"

docker run --rm \
    -v "${BUILD_DIR}:/workspace" \
    -w /workspace \
    --platform linux/amd64 \
    golang:1.25-bookworm \
    bash -c "
        set -e
        export CGO_ENABLED=0
        export GOOS=linux
        export GOARCH=amd64
        go build -trimpath -buildmode=pie -ldflags='-s -w' -o nrdot-collector-host-linux-amd64 .
        chmod +x nrdot-collector-host-linux-amd64
    "

if [ -f "${BUILD_DIR}/nrdot-collector-host-linux-amd64" ]; then
    cp "${BUILD_DIR}/nrdot-collector-host-linux-amd64" "${OUTPUT_DIR}/"
    echo "✅ Linux AMD64 binary created: ${OUTPUT_DIR}/nrdot-collector-host-linux-amd64"
    echo "   Size: $(du -h ${OUTPUT_DIR}/nrdot-collector-host-linux-amd64 | cut -f1)"
else
    echo "❌ Failed to create Linux AMD64 binary"
    exit 1
fi

# Build Linux ARM64 using Docker with cross-compilation
echo ""
echo "======================================"
echo "Building Linux ARM64"
echo "======================================"

docker run --rm \
    -v "${BUILD_DIR}:/workspace" \
    -w /workspace \
    --platform linux/amd64 \
    golang:1.25-bookworm \
    bash -c "
        set -e
        export CGO_ENABLED=0
        export GOOS=linux
        export GOARCH=arm64
        go build -trimpath -buildmode=pie -ldflags='-s -w' -o nrdot-collector-host-linux-arm64 .
        chmod +x nrdot-collector-host-linux-arm64
    "

if [ -f "${BUILD_DIR}/nrdot-collector-host-linux-arm64" ]; then
    cp "${BUILD_DIR}/nrdot-collector-host-linux-arm64" "${OUTPUT_DIR}/"
    echo "✅ Linux ARM64 binary created: ${OUTPUT_DIR}/nrdot-collector-host-linux-arm64"
    echo "   Size: $(du -h ${OUTPUT_DIR}/nrdot-collector-host-linux-arm64 | cut -f1)"
else
    echo "❌ Failed to create Linux ARM64 binary"
    exit 1
fi

# Build Windows AMD64 using Docker
echo ""
echo "======================================"
echo "Building Windows AMD64"
echo "======================================"

docker run --rm \
    -v "${BUILD_DIR}:/workspace" \
    -w /workspace \
    --platform linux/amd64 \
    golang:1.25-bookworm \
    bash -c "
        set -e
        export CGO_ENABLED=0
        export GOOS=windows
        export GOARCH=amd64
        go build -trimpath -buildmode=pie -ldflags='-s -w' -o nrdot-collector-host-windows-amd64.exe .
    "

if [ -f "${BUILD_DIR}/nrdot-collector-host-windows-amd64.exe" ]; then
    cp "${BUILD_DIR}/nrdot-collector-host-windows-amd64.exe" "${OUTPUT_DIR}/"
    echo "✅ Windows AMD64 binary created: ${OUTPUT_DIR}/nrdot-collector-host-windows-amd64.exe"
    echo "   Size: $(du -h ${OUTPUT_DIR}/nrdot-collector-host-windows-amd64.exe | cut -f1)"
else
    echo "❌ Failed to create Windows AMD64 binary"
    exit 1
fi

# Create checksums
echo ""
echo "======================================"
echo "Creating SHA256 checksums"
echo "======================================"

cd "${OUTPUT_DIR}"
for binary in nrdot-collector-host-*; do
    if [ -f "${binary}" ]; then
        shasum -a 256 "${binary}" > "${binary}.sha256"
        echo "✅ Checksum created: ${binary}.sha256"
    fi
done

echo ""
echo "======================================"
echo "Build Summary"
echo "======================================"
echo "All binaries created in: ${OUTPUT_DIR}"
ls -lh "${OUTPUT_DIR}"

echo ""
echo "✅ All binaries built successfully!"
