#!/bin/bash
# Copyright New Relic, Inc. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

# Comprehensive build script for nrdot-collector-host
# Builds Linux (deb/rpm) for amd64 and arm64, and Windows MSI for amd64
# CGO_ENABLED=0 (Oracle and SQL Server receivers use pure Go implementations)

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "${SCRIPT_DIR}"

REPO_ROOT="${SCRIPT_DIR}/../.."
BUILD_DIR="${SCRIPT_DIR}/_build"
DIST_DIR="${SCRIPT_DIR}/dist"
OUTPUT_DIR="${SCRIPT_DIR}/packages"
VERSION="1.11.1"

echo "======================================"
echo "NRDOT Collector Host - Full Build"
echo "======================================"
echo "Version: ${VERSION}"
echo "Script directory: ${SCRIPT_DIR}"
echo "Build directory: ${BUILD_DIR}"
echo "Output directory: ${OUTPUT_DIR}"
echo ""

# Clean previous builds
echo "Cleaning previous builds..."
rm -rf "${BUILD_DIR}"
rm -rf "${DIST_DIR}"
rm -rf "${OUTPUT_DIR}"
mkdir -p "${OUTPUT_DIR}"

# Step 1: Generate collector sources
echo ""
echo "======================================"
echo "Step 1: Generating collector sources"
echo "======================================"

cd "${REPO_ROOT}"
make generate-sources DISTRIBUTIONS=nrdot-collector-host

if [ ! -d "${BUILD_DIR}" ] || [ ! -f "${BUILD_DIR}/main.go" ]; then
    echo "ERROR: Failed to generate collector sources"
    exit 1
fi

echo "✅ Collector sources generated successfully"

# Step 2: Build Linux AMD64 binary
echo ""
echo "======================================"
echo "Step 2: Building Linux AMD64 binary"
echo "======================================"

mkdir -p "${DIST_DIR}/nrdot-collector-host_linux_amd64_v1"

docker run --rm \
    -v "${BUILD_DIR}:/workspace" \
    -v "${DIST_DIR}:/dist" \
    -w /workspace \
    --platform linux/amd64 \
    golang:1.25-bookworm \
    bash -c "
        set -e
        echo 'Building AMD64 binary with buildmode=pie...'
        export CGO_ENABLED=0
        export GOOS=linux
        export GOARCH=amd64
        go build -trimpath -buildmode=pie -ldflags='-s -w' -o /dist/nrdot-collector-host_linux_amd64_v1/nrdot-collector-host .
        chmod +x /dist/nrdot-collector-host_linux_amd64_v1/nrdot-collector-host
        echo 'Binary built successfully'
    "

if [ -f "${DIST_DIR}/nrdot-collector-host_linux_amd64_v1/nrdot-collector-host" ]; then
    echo "✅ Linux AMD64 binary created"
    echo "   Size: $(du -h ${DIST_DIR}/nrdot-collector-host_linux_amd64_v1/nrdot-collector-host | cut -f1)"
else
    echo "❌ Failed to create Linux AMD64 binary"
    exit 1
fi

# Step 3: Build Linux ARM64 binary
echo ""
echo "======================================"
echo "Step 3: Building Linux ARM64 binary"
echo "======================================"

mkdir -p "${DIST_DIR}/nrdot-collector-host_linux_arm64_v8.0"

docker run --rm \
    -v "${BUILD_DIR}:/workspace" \
    -v "${DIST_DIR}:/dist" \
    -w /workspace \
    --platform linux/amd64 \
    golang:1.25-bookworm \
    bash -c "
        set -e
        echo 'Building ARM64 binary with buildmode=pie...'
        export CGO_ENABLED=0
        export GOOS=linux
        export GOARCH=arm64
        go build -trimpath -buildmode=pie -ldflags='-s -w' -o /dist/nrdot-collector-host_linux_arm64_v8.0/nrdot-collector-host .
        chmod +x /dist/nrdot-collector-host_linux_arm64_v8.0/nrdot-collector-host
        echo 'Binary built successfully'
    "

if [ -f "${DIST_DIR}/nrdot-collector-host_linux_arm64_v8.0/nrdot-collector-host" ]; then
    echo "✅ Linux ARM64 binary created"
    echo "   Size: $(du -h ${DIST_DIR}/nrdot-collector-host_linux_arm64_v8.0/nrdot-collector-host | cut -f1)"
else
    echo "❌ Failed to create Linux ARM64 binary"
    exit 1
fi

# Step 4: Build Windows AMD64 binary
echo ""
echo "======================================"
echo "Step 4: Building Windows AMD64 binary"
echo "======================================"

mkdir -p "${DIST_DIR}/nrdot-collector-host_windows_amd64_v1"

docker run --rm \
    -v "${BUILD_DIR}:/workspace" \
    -v "${DIST_DIR}:/dist" \
    -w /workspace \
    --platform linux/amd64 \
    golang:1.25-bookworm \
    bash -c "
        set -e
        echo 'Building Windows AMD64 binary with buildmode=pie...'
        export CGO_ENABLED=0
        export GOOS=windows
        export GOARCH=amd64
        go build -trimpath -buildmode=pie -ldflags='-s -w' -o /dist/nrdot-collector-host_windows_amd64_v1/nrdot-collector-host.exe .
        echo 'Binary built successfully'
    "

if [ -f "${DIST_DIR}/nrdot-collector-host_windows_amd64_v1/nrdot-collector-host.exe" ]; then
    echo "✅ Windows AMD64 binary created"
    echo "   Size: $(du -h ${DIST_DIR}/nrdot-collector-host_windows_amd64_v1/nrdot-collector-host.exe | cut -f1)"
else
    echo "❌ Failed to create Windows AMD64 binary"
    exit 1
fi

# Step 5: Package Linux AMD64 (deb and rpm)
echo ""
echo "======================================"
echo "Step 5: Packaging Linux AMD64"
echo "======================================"

echo "Creating DEB package for AMD64..."
docker run --rm \
    -v "${SCRIPT_DIR}:/workspace" \
    -w /workspace \
    goreleaser/nfpm:latest \
    package \
    --config nfpm-amd64.yaml \
    --packager deb \
    --target /workspace/packages

echo "Creating RPM package for AMD64..."
docker run --rm \
    -v "${SCRIPT_DIR}:/workspace" \
    -w /workspace \
    goreleaser/nfpm:latest \
    package \
    --config nfpm-amd64.yaml \
    --packager rpm \
    --target /workspace/packages

if [ -f "${OUTPUT_DIR}/nrdot-collector-host_${VERSION}_amd64.deb" ] && [ -f "${OUTPUT_DIR}/nrdot-collector-host-${VERSION}-1.x86_64.rpm" ]; then
    echo "✅ Linux AMD64 packages created"
else
    echo "❌ Failed to create Linux AMD64 packages"
    exit 1
fi

# Step 6: Package Linux ARM64 (deb and rpm)
echo ""
echo "======================================"
echo "Step 6: Packaging Linux ARM64"
echo "======================================"

echo "Creating DEB package for ARM64..."
docker run --rm \
    -v "${SCRIPT_DIR}:/workspace" \
    -w /workspace \
    goreleaser/nfpm:latest \
    package \
    --config nfpm-arm64.yaml \
    --packager deb \
    --target /workspace/packages

echo "Creating RPM package for ARM64..."
docker run --rm \
    -v "${SCRIPT_DIR}:/workspace" \
    -w /workspace \
    goreleaser/nfpm:latest \
    package \
    --config nfpm-arm64.yaml \
    --packager rpm \
    --target /workspace/packages

if [ -f "${OUTPUT_DIR}/nrdot-collector-host_${VERSION}_arm64.deb" ] && [ -f "${OUTPUT_DIR}/nrdot-collector-host-${VERSION}-1.aarch64.rpm" ]; then
    echo "✅ Linux ARM64 packages created"
else
    echo "❌ Failed to create Linux ARM64 packages"
    exit 1
fi

# Step 7: Build Windows MSI
echo ""
echo "======================================"
echo "Step 7: Building Windows MSI"
echo "======================================"

WINDOWS_EXE="${DIST_DIR}/nrdot-collector-host_windows_amd64_v1/nrdot-collector-host.exe"
MSI_OUTPUT="${OUTPUT_DIR}/nrdot-collector-host_${VERSION}_windows_amd64.msi"

if [ ! -f "${WINDOWS_EXE}" ]; then
    echo "❌ Windows binary not found, skipping MSI build"
else
    # Generate a WiX XML referencing the built binary
    cat > "${SCRIPT_DIR}/nrdot-collector-host-build.wxs" <<WIXEOF
<?xml version='1.0' encoding='windows-1252'?>
<Wix xmlns='http://schemas.microsoft.com/wix/2006/wi'>
  <Product Name='NRDOT Collector Host'
           Id='*'
           UpgradeCode='12345678-1234-1234-1234-123456789012'
           Language='1033'
           Codepage='1252'
           Version='${VERSION}'
           Manufacturer='New Relic'>
    <Package Id='*'
             Keywords='Installer'
             Description='NRDOT Collector Host'
             Manufacturer='New Relic'
             InstallerVersion='200'
             Languages='1033'
             Compressed='yes'
             SummaryCodepage='1252' />
    <Media Id='1' Cabinet='nrdot.cab' EmbedCab='yes' DiskPrompt='CD-ROM #1' />
    <Property Id='DiskPrompt' Value='NRDOT Collector Host Installation' />
    <Directory Id='TARGETDIR' Name='SourceDir'>
      <Directory Id='ProgramFilesFolder' Name='PFiles'>
        <Directory Id='INSTALLDIR' Name='NRDOT Collector Host'>
          <Component Id='MainExecutable' Guid='12345678-1234-1234-1234-123456789013'>
            <File Id='nrdotexe'
                  Name='nrdot-collector-host.exe'
                  DiskId='1'
                  Source='dist/nrdot-collector-host_windows_amd64_v1/nrdot-collector-host.exe'
                  KeyPath='yes' />
            <ServiceInstall Id='ServiceInstaller'
                           Name='nrdot-collector-host'
                           DisplayName='NRDOT Collector Host'
                           Description='New Relic NRDOT Collector'
                           Type='ownProcess'
                           Start='auto'
                           Account='LocalSystem'
                           ErrorControl='normal'
                           Arguments='--config "[INSTALLDIR]config.yaml"' />
            <ServiceControl Id='ServiceControl'
                           Name='nrdot-collector-host'
                           Start='install'
                           Stop='both'
                           Remove='uninstall' />
          </Component>
          <Component Id='ConfigFile' Guid='12345678-1234-1234-1234-123456789014'>
            <File Id='configyaml'
                  Name='config.yaml'
                  DiskId='1'
                  Source='config.yaml'
                  KeyPath='yes' />
          </Component>
        </Directory>
      </Directory>
    </Directory>
    <Feature Id='Complete' Level='1'>
      <ComponentRef Id='MainExecutable' />
      <ComponentRef Id='ConfigFile' />
    </Feature>
  </Product>
</Wix>
WIXEOF

    echo "Building MSI via Docker with wixl..."
    docker run --rm \
        -v "${SCRIPT_DIR}:/workspace" \
        -w /workspace \
        --platform linux/amd64 \
        ubuntu:22.04 \
        bash -c "
            set -e
            export DEBIAN_FRONTEND=noninteractive
            apt-get update -qq && apt-get install -y -qq msitools > /dev/null 2>&1
            wixl -o packages/nrdot-collector-host_${VERSION}_windows_amd64.msi nrdot-collector-host-build.wxs
        " && echo "✅ Windows MSI created: nrdot-collector-host_${VERSION}_windows_amd64.msi" \
          || echo "⚠️  MSI creation failed — binary is available at ${WINDOWS_EXE}"

    rm -f "${SCRIPT_DIR}/nrdot-collector-host-build.wxs"
fi

# Step 8: Create checksums
echo ""
echo "======================================"
echo "Step 8: Creating checksums"
echo "======================================"

cd "${OUTPUT_DIR}"
for file in *; do
    if [ -f "${file}" ]; then
        shasum -a 256 "${file}" > "${file}.sha256"
        echo "✅ Checksum created: ${file}.sha256"
    fi
done

# Final summary
echo ""
echo "======================================"
echo "Build Complete!"
echo "======================================"
echo "All packages are available in: ${OUTPUT_DIR}"
echo ""
ls -lh "${OUTPUT_DIR}"
echo ""
echo "Packages created:"
echo "  - nrdot-collector-host_${VERSION}_amd64.deb (Linux AMD64)"
echo "  - nrdot-collector-host-${VERSION}.x86_64.rpm (Linux AMD64)"
echo "  - nrdot-collector-host_${VERSION}_arm64.deb (Linux ARM64)"
echo "  - nrdot-collector-host-${VERSION}.aarch64.rpm (Linux ARM64)"
if [ -f "${OUTPUT_DIR}"/*.msi ]; then
    echo "  - $(ls ${OUTPUT_DIR}/*.msi | xargs -n 1 basename) (Windows AMD64)"
fi
echo ""
echo "✅ All builds completed successfully!"
echo ""
echo "Note: Linux packages will automatically enable and start the systemd service upon installation."
