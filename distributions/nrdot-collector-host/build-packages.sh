#!/bin/bash
# Build packages (deb, rpm, msi) for nrdot-collector-host with Oracle/SQL Server support

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

# Create a Docker image with goreleaser and cross-compilation tools
echo "Building Docker image with goreleaser..."
docker build -t nrdot-goreleaser:latest -f - . <<'DOCKERFILE'
FROM golang:1.24-bookworm

# Install build dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    gcc-aarch64-linux-gnu \
    g++-aarch64-linux-gnu \
    rpm \
    make \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install goreleaser
RUN wget -q https://github.com/goreleaser/goreleaser/releases/download/v2.6.1/goreleaser_Linux_x86_64.tar.gz && \
    tar -xzf goreleaser_Linux_x86_64.tar.gz && \
    mv goreleaser /usr/local/bin/ && \
    rm goreleaser_Linux_x86_64.tar.gz

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
        export CGO_ENABLED=1
        goreleaser build --clean --snapshot --config .goreleaser-db-receivers.yaml
        goreleaser release --clean --snapshot --skip=publish,sign,validate --config .goreleaser-db-receivers.yaml
    "

if [ -d "${DIST_DIR}" ]; then
    echo ""
    echo "✅ Linux packages created:"
    find "${DIST_DIR}" -name "*.deb" -o -name "*.rpm" | while read pkg; do
        echo "   - $(basename $pkg) ($(du -h "$pkg" | cut -f1))"
    done
else
    echo "❌ Failed to create Linux packages"
    exit 1
fi

echo ""
echo "======================================"
echo "Building Windows MSI installer"
echo "======================================"

# Check if wixl is available (WiX toolset for creating MSI)
if ! command -v wixl &> /dev/null; then
    echo "Installing msitools (wixl) for MSI creation..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew install msitools 2>/dev/null || echo "Warning: Could not install msitools. MSI creation may fail."
    else
        echo "Warning: wixl not found. MSI creation may fail."
    fi
fi

# Check if Windows binary exists in binaries directory
WINDOWS_BINARY="${SCRIPT_DIR}/binaries/nrdot-collector-host-windows-amd64.exe"
if [ ! -f "${WINDOWS_BINARY}" ]; then
    echo "ERROR: Windows binary not found at ${WINDOWS_BINARY}"
    echo "Please run build-all-binaries.sh first"
    exit 1
fi

# Create MSI using WiX
MSI_OUTPUT="${DIST_DIR}/nrdot-collector-host_${VERSION}_windows_amd64.msi"

# Check if .wxs file exists
WXS_FILE="${SCRIPT_DIR}/nrdot-collector-host.wxs"
if [ -f "${WXS_FILE}" ]; then
    echo "Creating MSI installer..."

    # Copy binary to dist for packaging
    mkdir -p "${DIST_DIR}/windows_tmp"
    cp "${WINDOWS_BINARY}" "${DIST_DIR}/windows_tmp/"
    cp "${SCRIPT_DIR}/config.yaml" "${DIST_DIR}/windows_tmp/" 2>/dev/null || echo "Warning: config.yaml not found"

    # Try to create MSI
    if command -v wixl &> /dev/null; then
        wixl -o "${MSI_OUTPUT}" "${WXS_FILE}" 2>&1 || echo "Warning: MSI creation with wixl failed"
    else
        echo "Note: wixl not available. MSI will need to be created on Windows with WiX toolset."
        echo "      Windows binary is available at: ${WINDOWS_BINARY}"
    fi

    rm -rf "${DIST_DIR}/windows_tmp"
else
    echo "Note: .wxs file not found. MSI will need to be created manually."
    echo "      Windows binary is available at: ${WINDOWS_BINARY}"
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
echo "Windows Binary:"
if [ -f "${WINDOWS_BINARY}" ]; then
    echo "  ✅ $(basename ${WINDOWS_BINARY})"
else
    echo "  ❌ Windows binary not found"
fi

echo ""
echo "Windows MSI:"
if [ -f "${MSI_OUTPUT}" ]; then
    echo "  ✅ $(basename ${MSI_OUTPUT})"
else
    echo "  ⚠️  MSI not created (requires WiX toolset on Windows or wixl on macOS/Linux)"
fi

echo ""
echo "======================================"
echo "Build completed!"
echo "======================================"
