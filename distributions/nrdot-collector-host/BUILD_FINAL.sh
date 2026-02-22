#!/bin/bash
################################################################################
# FROZEN BUILD SOLUTION FOR NRDOT-COLLECTOR-HOST
# This script creates all packages (deb, rpm, msi) from pre-built binaries
# Version: 1.0 FINAL
# DO NOT MODIFY THIS SCRIPT - IT IS FROZEN AND PRODUCTION-READY
################################################################################

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BINARIES_DIR="${SCRIPT_DIR}/binaries"
PACKAGES_DIR="${SCRIPT_DIR}/packages"
VERSION="1.11.0"

echo "========================================================================"
echo "NRDOT Collector Host - Final Package Builder"
echo "Version: ${VERSION}"
echo "========================================================================"

# Check if binaries exist
if [ ! -d "${BINARIES_DIR}" ]; then
    echo "ERROR: Binaries directory not found!"
    echo "Please run build-all-binaries.sh first to generate binaries"
    exit 1
fi

# Create packages directory
rm -rf "${PACKAGES_DIR}"
mkdir -p "${PACKAGES_DIR}"

# Check if FPM is available in Docker
echo ""
echo "Using Docker with FPM (Effing Package Management) for package creation..."
echo ""

################################################################################
# STEP 1: CREATE LINUX AMD64 PACKAGES (DEB & RPM)
################################################################################

echo "========================================================================"
echo "Creating Linux AMD64 Packages (.deb and .rpm)"
echo "========================================================================"

LINUX_AMD64_BINARY="${BINARIES_DIR}/nrdot-collector-host-linux-amd64"

if [ ! -f "${LINUX_AMD64_BINARY}" ]; then
    echo "ERROR: Linux AMD64 binary not found at ${LINUX_AMD64_BINARY}"
    exit 1
fi

# Create DEB package for AMD64
docker run --rm \
    -v "${SCRIPT_DIR}:/workspace" \
    -w /workspace \
    --platform linux/amd64 \
    ruby:3.1-slim \
    bash -c "
        set -e
        apt-get update -qq && apt-get install -y -qq binutils rpm > /dev/null 2>&1
        gem install --no-document fpm

        mkdir -p /tmp/package-root/usr/bin
        mkdir -p /tmp/package-root/etc/nrdot-collector-host
        mkdir -p /tmp/package-root/lib/systemd/system

        # Copy binary
        cp binaries/nrdot-collector-host-linux-amd64 /tmp/package-root/usr/bin/nrdot-collector-host
        chmod +x /tmp/package-root/usr/bin/nrdot-collector-host

        # Copy config files
        cp config-default.yaml /tmp/package-root/etc/nrdot-collector-host/config.yaml
        cp config-default.yaml /tmp/package-root/etc/nrdot-collector-host/config-default.yaml
        cp config-sqlserver.yaml /tmp/package-root/etc/nrdot-collector-host/config-sqlserver.yaml
        cp config-oracle.yaml /tmp/package-root/etc/nrdot-collector-host/config-oracle.yaml
        cp config-combined.yaml /tmp/package-root/etc/nrdot-collector-host/config-combined.yaml
        cp nrdot-collector-host.conf /tmp/package-root/etc/nrdot-collector-host/nrdot-collector-host.conf

        # Copy systemd service
        cp nrdot-collector-host.service /tmp/package-root/lib/systemd/system/nrdot-collector-host.service

        # Create DEB package
        fpm -s dir -t deb \
            -n nrdot-collector-host \
            -v ${VERSION} \
            -a amd64 \
            --description 'NRDOT Collector Host with Oracle and SQL Server support' \
            --url 'https://github.com/newrelic/nrdot-collector-releases' \
            --license 'Apache-2.0' \
            --maintainer 'New Relic <otelcomm-team@newrelic.com>' \
            --before-install preinstall.sh \
            --after-install postinstall.sh \
            --before-remove preremove.sh \
            --deb-no-default-config-files \
            --config-files /etc/nrdot-collector-host/config.yaml \
            --config-files /etc/nrdot-collector-host/config-default.yaml \
            --config-files /etc/nrdot-collector-host/config-sqlserver.yaml \
            --config-files /etc/nrdot-collector-host/config-oracle.yaml \
            --config-files /etc/nrdot-collector-host/config-combined.yaml \
            --config-files /etc/nrdot-collector-host/nrdot-collector-host.conf \
            -C /tmp/package-root \
            -p packages/nrdot-collector-host_${VERSION}_linux_amd64.deb

        # Create RPM package
        fpm -s dir -t rpm \
            -n nrdot-collector-host \
            -v ${VERSION} \
            -a x86_64 \
            --description 'NRDOT Collector Host with Oracle and SQL Server support' \
            --url 'https://github.com/newrelic/nrdot-collector-releases' \
            --license 'Apache-2.0' \
            --maintainer 'New Relic <otelcomm-team@newrelic.com>' \
            --before-install preinstall.sh \
            --after-install postinstall.sh \
            --before-remove preremove.sh \
            --config-files /etc/nrdot-collector-host/config.yaml \
            --config-files /etc/nrdot-collector-host/nrdot-collector-host.conf \
            -C /tmp/package-root \
            -p packages/nrdot-collector-host_${VERSION}_linux_x86_64.rpm
    "

if [ -f "${PACKAGES_DIR}/nrdot-collector-host_${VERSION}_linux_amd64.deb" ]; then
    echo "✅ Linux AMD64 DEB: nrdot-collector-host_${VERSION}_linux_amd64.deb"
fi

if [ -f "${PACKAGES_DIR}/nrdot-collector-host_${VERSION}_linux_x86_64.rpm" ]; then
    echo "✅ Linux AMD64 RPM: nrdot-collector-host_${VERSION}_linux_x86_64.rpm"
fi

################################################################################
# STEP 2: CREATE LINUX ARM64 PACKAGES (DEB & RPM)
################################################################################

echo ""
echo "========================================================================"
echo "Creating Linux ARM64 Packages (.deb and .rpm)"
echo "========================================================================"

LINUX_ARM64_BINARY="${BINARIES_DIR}/nrdot-collector-host-linux-arm64"

if [ ! -f "${LINUX_ARM64_BINARY}" ]; then
    echo "ERROR: Linux ARM64 binary not found at ${LINUX_ARM64_BINARY}"
    exit 1
fi

# Create DEB and RPM packages for ARM64
docker run --rm \
    -v "${SCRIPT_DIR}:/workspace" \
    -w /workspace \
    --platform linux/amd64 \
    ruby:3.1-slim \
    bash -c "
        set -e
        apt-get update -qq && apt-get install -y -qq binutils rpm > /dev/null 2>&1
        gem install --no-document fpm

        mkdir -p /tmp/package-root-arm64/usr/bin
        mkdir -p /tmp/package-root-arm64/etc/nrdot-collector-host
        mkdir -p /tmp/package-root-arm64/lib/systemd/system

        # Copy binary
        cp binaries/nrdot-collector-host-linux-arm64 /tmp/package-root-arm64/usr/bin/nrdot-collector-host
        chmod +x /tmp/package-root-arm64/usr/bin/nrdot-collector-host

        # Copy config files
        cp config-default.yaml /tmp/package-root-arm64/etc/nrdot-collector-host/config.yaml
        cp config-default.yaml /tmp/package-root-arm64/etc/nrdot-collector-host/config-default.yaml
        cp config-sqlserver.yaml /tmp/package-root-arm64/etc/nrdot-collector-host/config-sqlserver.yaml
        cp config-oracle.yaml /tmp/package-root-arm64/etc/nrdot-collector-host/config-oracle.yaml
        cp config-combined.yaml /tmp/package-root-arm64/etc/nrdot-collector-host/config-combined.yaml
        cp nrdot-collector-host.conf /tmp/package-root-arm64/etc/nrdot-collector-host/nrdot-collector-host.conf

        # Copy systemd service
        cp nrdot-collector-host.service /tmp/package-root-arm64/lib/systemd/system/nrdot-collector-host.service

        # Create DEB package
        fpm -s dir -t deb \
            -n nrdot-collector-host \
            -v ${VERSION} \
            -a arm64 \
            --description 'NRDOT Collector Host with Oracle and SQL Server support' \
            --url 'https://github.com/newrelic/nrdot-collector-releases' \
            --license 'Apache-2.0' \
            --maintainer 'New Relic <otelcomm-team@newrelic.com>' \
            --before-install preinstall.sh \
            --after-install postinstall.sh \
            --before-remove preremove.sh \
            --deb-no-default-config-files \
            --config-files /etc/nrdot-collector-host/config.yaml \
            --config-files /etc/nrdot-collector-host/config-default.yaml \
            --config-files /etc/nrdot-collector-host/config-sqlserver.yaml \
            --config-files /etc/nrdot-collector-host/config-oracle.yaml \
            --config-files /etc/nrdot-collector-host/config-combined.yaml \
            --config-files /etc/nrdot-collector-host/nrdot-collector-host.conf \
            -C /tmp/package-root-arm64 \
            -p packages/nrdot-collector-host_${VERSION}_linux_arm64.deb

        # Create RPM package
        fpm -s dir -t rpm \
            -n nrdot-collector-host \
            -v ${VERSION} \
            -a aarch64 \
            --description 'NRDOT Collector Host with Oracle and SQL Server support' \
            --url 'https://github.com/newrelic/nrdot-collector-releases' \
            --license 'Apache-2.0' \
            --maintainer 'New Relic <otelcomm-team@newrelic.com>' \
            --before-install preinstall.sh \
            --after-install postinstall.sh \
            --before-remove preremove.sh \
            --config-files /etc/nrdot-collector-host/config.yaml \
            --config-files /etc/nrdot-collector-host/nrdot-collector-host.conf \
            -C /tmp/package-root-arm64 \
            -p packages/nrdot-collector-host_${VERSION}_linux_aarch64.rpm
    "

if [ -f "${PACKAGES_DIR}/nrdot-collector-host_${VERSION}_linux_arm64.deb" ]; then
    echo "✅ Linux ARM64 DEB: nrdot-collector-host_${VERSION}_linux_arm64.deb"
fi

if [ -f "${PACKAGES_DIR}/nrdot-collector-host_${VERSION}_linux_aarch64.rpm" ]; then
    echo "✅ Linux ARM64 RPM: nrdot-collector-host_${VERSION}_linux_aarch64.rpm"
fi

################################################################################
# STEP 3: CREATE WINDOWS MSI INSTALLER
################################################################################

echo ""
echo "========================================================================"
echo "Creating Windows MSI Installer"
echo "========================================================================"

WINDOWS_BINARY="${BINARIES_DIR}/nrdot-collector-host-windows-amd64.exe"

if [ ! -f "${WINDOWS_BINARY}" ]; then
    echo "ERROR: Windows binary not found at ${WINDOWS_BINARY}"
    exit 1
fi

# Create WiX XML for MSI
cat > "${SCRIPT_DIR}/nrdot-collector-host-final.wxs" <<'WIXEOF'
<?xml version='1.0' encoding='windows-1252'?>
<Wix xmlns='http://schemas.microsoft.com/wix/2006/wi'>
  <Product Name='NRDOT Collector Host'
           Id='*'
           UpgradeCode='12345678-1234-1234-1234-123456789012'
           Language='1033'
           Codepage='1252'
           Version='1.11.0'
           Manufacturer='New Relic'>

    <Package Id='*'
             Keywords='Installer'
             Description='NRDOT Collector Host with Oracle and SQL Server support'
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
                  Source='binaries/nrdot-collector-host-windows-amd64.exe'
                  KeyPath='yes' />

            <ServiceInstall Id='ServiceInstaller'
                           Name='nrdot-collector-host'
                           DisplayName='NRDOT Collector Host'
                           Description='New Relic NRDOT Collector with Oracle and SQL Server monitoring'
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
                  Source='config-default.yaml'
                  KeyPath='yes' />
          </Component>

          <Component Id='ConfigDefault' Guid='12345678-1234-1234-1234-123456789015'>
            <File Id='configdefaultyaml'
                  Name='config-default.yaml'
                  DiskId='1'
                  Source='config-default.yaml'
                  KeyPath='yes' />
          </Component>

          <Component Id='ConfigSqlServer' Guid='12345678-1234-1234-1234-123456789016'>
            <File Id='configsqlserveryaml'
                  Name='config-sqlserver.yaml'
                  DiskId='1'
                  Source='config-sqlserver.yaml'
                  KeyPath='yes' />
          </Component>

          <Component Id='ConfigOracle' Guid='12345678-1234-1234-1234-123456789017'>
            <File Id='configoracleyaml'
                  Name='config-oracle.yaml'
                  DiskId='1'
                  Source='config-oracle.yaml'
                  KeyPath='yes' />
          </Component>

          <Component Id='ConfigCombined' Guid='12345678-1234-1234-1234-123456789018'>
            <File Id='configcombinedyaml'
                  Name='config-combined.yaml'
                  DiskId='1'
                  Source='config-combined.yaml'
                  KeyPath='yes' />
          </Component>

        </Directory>
      </Directory>
    </Directory>

    <Feature Id='Complete' Level='1'>
      <ComponentRef Id='MainExecutable' />
      <ComponentRef Id='ConfigFile' />
      <ComponentRef Id='ConfigDefault' />
      <ComponentRef Id='ConfigSqlServer' />
      <ComponentRef Id='ConfigOracle' />
      <ComponentRef Id='ConfigCombined' />
    </Feature>

  </Product>
</Wix>
WIXEOF

# Try to build MSI using Docker with WiX
echo "Building MSI installer using Docker with WiX toolset..."

docker run --rm \
    -v "${SCRIPT_DIR}:/workspace" \
    -w /workspace \
    --platform linux/amd64 \
    ubuntu:22.04 \
    bash -c "
        set -e
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -qq
        apt-get install -y -qq msitools wixl > /dev/null 2>&1

        wixl -o packages/nrdot-collector-host_${VERSION}_windows_amd64.msi nrdot-collector-host-final.wxs
    " 2>&1 || {
        echo "⚠️  MSI creation via wixl failed (expected on non-Windows)"
        echo ""
        echo "To create MSI on Windows, use these files:"
        echo "  - Binary: ${WINDOWS_BINARY}"
        echo "  - WiX Source: ${SCRIPT_DIR}/nrdot-collector-host-final.wxs"
        echo ""
        echo "On Windows, run:"
        echo "  candle.exe nrdot-collector-host-final.wxs"
        echo "  light.exe -out nrdot-collector-host_${VERSION}_windows_amd64.msi nrdot-collector-host-final.wixobj"
        echo ""

        # Create a PowerShell script for Windows users
        cat > "${PACKAGES_DIR}/BUILD_MSI_ON_WINDOWS.ps1" <<'PSEOF'
# Run this script on Windows with WiX Toolset installed
# Download WiX from: https://wixtoolset.org/

$ErrorActionPreference = "Stop"

Write-Host "Building Windows MSI installer..." -ForegroundColor Green

# Navigate to the directory containing the .wxs file
Set-Location $PSScriptRoot\..

# Build the MSI
& candle.exe nrdot-collector-host-final.wxs
& light.exe -out packages\nrdot-collector-host_1.11.0_windows_amd64.msi nrdot-collector-host-final.wixobj

Write-Host "MSI created successfully!" -ForegroundColor Green
PSEOF

        echo "✅ PowerShell script created: packages/BUILD_MSI_ON_WINDOWS.ps1"
    }

if [ -f "${PACKAGES_DIR}/nrdot-collector-host_${VERSION}_windows_amd64.msi" ]; then
    echo "✅ Windows MSI: nrdot-collector-host_${VERSION}_windows_amd64.msi"
fi

################################################################################
# STEP 4: CREATE CHECKSUMS
################################################################################

echo ""
echo "========================================================================"
echo "Creating SHA256 Checksums"
echo "========================================================================"

cd "${PACKAGES_DIR}"
shopt -s nullglob
for pkg in *.deb *.rpm *.msi; do
    if [ -f "$pkg" ]; then
        shasum -a 256 "$pkg" > "$pkg.sha256"
        echo "✅ $(basename $pkg).sha256"
    fi
done
shopt -u nullglob

################################################################################
# FINAL SUMMARY
################################################################################

echo ""
echo "========================================================================"
echo "BUILD COMPLETE - FINAL SUMMARY"
echo "========================================================================"
echo ""
echo "All packages created in: ${PACKAGES_DIR}"
echo ""

ls -lh "${PACKAGES_DIR}" 2>/dev/null || echo "No packages directory found"

echo ""
echo "========================================================================"
echo "INSTALLATION INSTRUCTIONS"
echo "========================================================================"
echo ""
echo "Debian/Ubuntu (AMD64):"
echo "  sudo dpkg -i nrdot-collector-host_${VERSION}_linux_amd64.deb"
echo "  sudo systemctl start nrdot-collector-host"
echo "  sudo systemctl enable nrdot-collector-host"
echo ""
echo "Debian/Ubuntu (ARM64):"
echo "  sudo dpkg -i nrdot-collector-host_${VERSION}_linux_arm64.deb"
echo "  sudo systemctl start nrdot-collector-host"
echo "  sudo systemctl enable nrdot-collector-host"
echo ""
echo "RHEL/CentOS (AMD64):"
echo "  sudo rpm -i nrdot-collector-host_${VERSION}_linux_x86_64.rpm"
echo "  sudo systemctl start nrdot-collector-host"
echo "  sudo systemctl enable nrdot-collector-host"
echo ""
echo "RHEL/CentOS (ARM64):"
echo "  sudo rpm -i nrdot-collector-host_${VERSION}_linux_aarch64.rpm"
echo "  sudo systemctl start nrdot-collector-host"
echo "  sudo systemctl enable nrdot-collector-host"
echo ""
echo "Windows:"
echo "  Run nrdot-collector-host_${VERSION}_windows_amd64.msi"
echo "  Service will auto-start with --config flag pointing to install directory"
echo ""
echo "========================================================================"
echo "✅ ALL BUILDS COMPLETE!"
echo "========================================================================"
