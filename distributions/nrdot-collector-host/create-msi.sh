#!/bin/bash
set -e

VERSION="1.11.1-SNAPSHOT-c403bb8"
PRODUCT_NAME="NRDOT Collector Host"
MANUFACTURER="New Relic"
BINARY_PATH="dist/nrdot-collector-host_windows_amd64_v1/nrdot-collector-host.exe"
CONFIG_PATH="distributions/nrdot-collector-host/config.yaml"
OUTPUT_MSI="binaries/nrdot-collector-host_${VERSION}_windows_amd64.msi"

# Create temporary directory for MSI contents
TEMP_DIR=$(mktemp -d)
mkdir -p "${TEMP_DIR}/PFiles/NRDOT Collector Host"
mkdir -p "${TEMP_DIR}/PFiles/NRDOT Collector Host/config"

# Copy files
cp "${BINARY_PATH}" "${TEMP_DIR}/PFiles/NRDOT Collector Host/"
cp "${CONFIG_PATH}" "${TEMP_DIR}/PFiles/NRDOT Collector Host/config/"

# Create WiX source file
cat > "${TEMP_DIR}/product.wxs" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<Wix xmlns="http://schemas.microsoft.com/wix/2006/wi">
  <Product
    Id="*"
    Name="NRDOT Collector Host"
    Language="1033"
    Version="1.11.1"
    Manufacturer="New Relic"
    UpgradeCode="A1B2C3D4-E5F6-7890-ABCD-EF1234567890">

    <Package
      InstallerVersion="200"
      Compressed="yes"
      InstallScope="perMachine"
      Description="NRDOT Collector Host with Oracle and SQL Server support"
      Comments="Built with CGO enabled for database receiver support" />

    <MajorUpgrade
      DowngradeErrorMessage="A newer version is already installed."
      AllowSameVersionUpgrades="yes" />

    <MediaTemplate EmbedCab="yes" />

    <Feature Id="ProductFeature" Title="NRDOT Collector Host" Level="1">
      <ComponentGroupRef Id="ProductComponents" />
    </Feature>

    <Directory Id="TARGETDIR" Name="SourceDir">
      <Directory Id="ProgramFiles64Folder">
        <Directory Id="INSTALLFOLDER" Name="NRDOT Collector Host" />
      </Directory>
    </Directory>

    <ComponentGroup Id="ProductComponents" Directory="INSTALLFOLDER">
      <Component Id="MainExecutable" Guid="12345678-ABCD-EF12-3456-789ABCDEF012">
        <File
          Id="nrdotcollectorhostEXE"
          Source="nrdot-collector-host.exe"
          KeyPath="yes" />
      </Component>
      <Component Id="ConfigDir" Guid="23456789-BCDE-F123-4567-89ABCDEF0123">
        <CreateFolder Directory="INSTALLFOLDER" />
        <File
          Id="configYAML"
          Source="config/config.yaml" />
      </Component>
    </ComponentGroup>

  </Product>
</Wix>
EOF

# Build MSI using wixl (from msitools)
cd "${TEMP_DIR}/PFiles/NRDOT Collector Host"
wixl -v -o "../../../${OUTPUT_MSI##*/}" "../../product.wxs"

# Move MSI to output directory
mkdir -p "$(dirname ${OUTPUT_MSI})"
mv "${TEMP_DIR}/${OUTPUT_MSI##*/}" "${OUTPUT_MSI}"

# Clean up
rm -rf "${TEMP_DIR}"

echo "MSI created successfully: ${OUTPUT_MSI}"
ls -lh "${OUTPUT_MSI}"
