#!/bin/bash
# Copyright New Relic, Inc. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

################################################################################
# IMPROVED MSI Builder - Includes MinGW DLLs and Better Service Configuration
################################################################################

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BINARIES_DIR="${SCRIPT_DIR}/binaries"
PACKAGES_DIR="${SCRIPT_DIR}/packages"
VERSION="1.11.0"

echo "========================================================================"
echo "Creating Improved Windows MSI Installer"
echo "========================================================================"

WINDOWS_BINARY="${BINARIES_DIR}/nrdot-collector-host-windows-amd64.exe"

if [ ! -f "${WINDOWS_BINARY}" ]; then
    echo "ERROR: Windows binary not found at ${WINDOWS_BINARY}"
    exit 1
fi

echo "Binary found: ${WINDOWS_BINARY}"
ls -lh "${WINDOWS_BINARY}"

# Create packages directory
mkdir -p "${PACKAGES_DIR}"

# Extract MinGW DLLs from the build container
echo ""
echo "Extracting MinGW runtime DLLs..."
docker run --rm \
    -v "${BINARIES_DIR}:/output" \
    --platform linux/amd64 \
    golang:1.24-bookworm \
    bash -c "
        set -e
        apt-get update -qq && apt-get install -y -qq mingw-w64 > /dev/null 2>&1

        # Copy required MinGW DLLs
        cp /usr/x86_64-w64-mingw32/lib/libgcc_s_seh-1.dll /output/ 2>/dev/null || echo 'libgcc_s_seh-1.dll not found'
        cp /usr/x86_64-w64-mingw32/lib/libwinpthread-1.dll /output/ 2>/dev/null || echo 'libwinpthread-1.dll not found'
        cp /usr/x86_64-w64-mingw32/lib/libstdc++-6.dll /output/ 2>/dev/null || echo 'libstdc++-6.dll not found'

        # Alternative locations
        find /usr -name 'libgcc_s_seh-1.dll' -exec cp {} /output/ \; 2>/dev/null || true
        find /usr -name 'libwinpthread-1.dll' -exec cp {} /output/ \; 2>/dev/null || true
        find /usr -name 'libstdc++-6.dll' -exec cp {} /output/ \; 2>/dev/null || true

        ls -lh /output/*.dll 2>/dev/null || echo 'No DLLs found - collector may need manual DLL installation'
    "

# Create improved WiX XML for MSI with DLLs and better service configuration
cat > "${SCRIPT_DIR}/nrdot-collector-host-improved.wxs" <<'WIXEOF'
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
             Description='NRDOT Collector Host with Oracle and SQL Server support (CGO-enabled with MinGW runtime)'
             Manufacturer='New Relic'
             InstallerVersion='200'
             Languages='1033'
             Compressed='yes'
             InstallPrivileges='elevated'
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

            <!-- Service Installation - Manual start by default -->
            <ServiceInstall Id='ServiceInstaller'
                           Name='nrdot-collector-host'
                           DisplayName='NRDOT Collector Host'
                           Description='New Relic NRDOT Collector with Oracle and SQL Server monitoring'
                           Type='ownProcess'
                           Start='demand'
                           Account='LocalSystem'
                           ErrorControl='normal'
                           Arguments='--config "[INSTALLDIR]config.yaml"' />

            <ServiceControl Id='ServiceControl'
                           Name='nrdot-collector-host'
                           Start='install'
                           Stop='both'
                           Remove='uninstall'
                           Wait='no' />
          </Component>

          <Component Id='ConfigFile' Guid='12345678-1234-1234-1234-123456789014'>
            <File Id='configyaml'
                  Name='config.yaml'
                  DiskId='1'
                  Source='config.yaml'
                  KeyPath='yes' />
          </Component>

          <!-- MinGW Runtime DLLs (optional - include if available) -->
          <Component Id='MinGWDLLs' Guid='12345678-1234-1234-1234-123456789019'>
            <File Id='libgcc' Name='libgcc_s_seh-1.dll' DiskId='1' Source='binaries/libgcc_s_seh-1.dll' KeyPath='yes' />
          </Component>

          <Component Id='MinGWDLL2' Guid='12345678-1234-1234-1234-123456789020'>
            <File Id='libwinpthread' Name='libwinpthread-1.dll' DiskId='1' Source='binaries/libwinpthread-1.dll' KeyPath='yes' />
          </Component>

          <Component Id='MinGWDLL3' Guid='12345678-1234-1234-1234-123456789021'>
            <File Id='libstdcpp' Name='libstdc++-6.dll' DiskId='1' Source='binaries/libstdc++-6.dll' KeyPath='yes' />
          </Component>

        </Directory>
      </Directory>
    </Directory>

    <Feature Id='Complete' Level='1' Title='NRDOT Collector Host' Description='Complete installation'>
      <ComponentRef Id='MainExecutable' />
      <ComponentRef Id='ConfigFile' />
      <ComponentRef Id='MinGWDLLs' />
      <ComponentRef Id='MinGWDLL2' />
      <ComponentRef Id='MinGWDLL3' />
    </Feature>

  </Product>
</Wix>
WIXEOF

echo "WiX XML created: nrdot-collector-host-improved.wxs"
echo "Building improved MSI installer using Docker with WiX toolset..."

# Check if DLLs were extracted
DLL_COUNT=$(ls -1 "${BINARIES_DIR}"/*.dll 2>/dev/null | wc -l)
if [ "$DLL_COUNT" -gt 0 ]; then
    echo "✅ Found $DLL_COUNT MinGW DLL(s) - will include in MSI"
    WXS_FILE="nrdot-collector-host-improved.wxs"
else
    echo "⚠️  MinGW DLLs not found - using fallback MSI (manual DLL installation required)"
    # Use simpler WXS without DLLs
    cat > "${SCRIPT_DIR}/nrdot-collector-host-nodll.wxs" <<'WIXEOF2'
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
             InstallPrivileges='elevated'
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
                           Start='demand'
                           Account='LocalSystem'
                           ErrorControl='normal'
                           Arguments='--config "[INSTALLDIR]config.yaml"' />

            <ServiceControl Id='ServiceControl'
                           Name='nrdot-collector-host'
                           Stop='both'
                           Remove='uninstall'
                           Wait='no' />
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
WIXEOF2
    WXS_FILE="nrdot-collector-host-nodll.wxs"
fi

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

        wixl -o packages/nrdot-collector-host_${VERSION}_windows_amd64_improved.msi ${WXS_FILE} 2>&1 || {
            echo '⚠️  wixl compilation failed, trying without DLL components...'
            wixl -o packages/nrdot-collector-host_${VERSION}_windows_amd64_improved.msi nrdot-collector-host-nodll.wxs
        }
    "

if [ -f "${PACKAGES_DIR}/nrdot-collector-host_${VERSION}_windows_amd64_improved.msi" ]; then
    echo ""
    echo "✅ Improved Windows MSI created successfully!"
    echo ""
    ls -lh "${PACKAGES_DIR}/nrdot-collector-host_${VERSION}_windows_amd64_improved.msi"
    echo ""
    echo "SHA256:"
    shasum -a 256 "${PACKAGES_DIR}/nrdot-collector-host_${VERSION}_windows_amd64_improved.msi"
    echo ""
    echo "Improvements in this MSI:"
    echo "  - Service set to 'Manual' start (Start='demand')"
    echo "  - Requires Administrator elevation (InstallPrivileges='elevated')"
    if [ "$DLL_COUNT" -gt 0 ]; then
        echo "  - Includes MinGW runtime DLLs: libgcc_s_seh-1.dll, libwinpthread-1.dll, libstdc++-6.dll"
    else
        echo "  - ⚠️  Does NOT include MinGW DLLs - manual installation may be required"
    fi
    echo ""
    echo "To install and start:"
    echo "  1. Right-click PowerShell and 'Run as Administrator'"
    echo "  2. msiexec /i nrdot-collector-host_${VERSION}_windows_amd64_improved.msi"
    echo "  3. Start-Service nrdot-collector-host"
else
    echo "❌ Failed to create improved MSI"
    exit 1
fi
