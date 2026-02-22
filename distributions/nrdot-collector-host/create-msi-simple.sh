#!/bin/bash
set -e

VERSION="1.11.1-SNAPSHOT-c403bb8"
BINARY_PATH="dist/nrdot-collector-host_windows_amd64_v1/nrdot-collector-host.exe"
CONFIG_PATH="distributions/nrdot-collector-host/config.yaml"
OUTPUT_MSI="binaries/nrdot-collector-host_${VERSION}_windows_amd64.msi"

# Create binaries directory
mkdir -p binaries

# Create temporary directory structure
TEMP_DIR=$(mktemp -d)
MSI_DIR="${TEMP_DIR}/msi"
mkdir -p "${MSI_DIR}/ProgramFilesFolder/NRDOT_Collector_Host"
mkdir -p "${MSI_DIR}/ProgramFilesFolder/NRDOT_Collector_Host/config"

# Copy files to temporary location
cp "${BINARY_PATH}" "${MSI_DIR}/ProgramFilesFolder/NRDOT_Collector_Host/"
cp "${CONFIG_PATH}" "${MSI_DIR}/ProgramFilesFolder/NRDOT_Collector_Host/config/"

# Use msibuild to create MSI
cd "${MSI_DIR}"
msibuild \
  -s "NRDOT Collector Host" \
  -n "nrdot-collector-host" \
  -v "${VERSION}" \
  -m "New Relic" \
  ProgramFilesFolder "${OUTPUT_MSI##*/}"

# Move MSI to binaries directory
cd /workspace
if [ -f "${MSI_DIR}/${OUTPUT_MSI##*/}" ]; then
  mv "${MSI_DIR}/${OUTPUT_MSI##*/}" "${OUTPUT_MSI}"
  echo "MSI created successfully: ${OUTPUT_MSI}"
  ls -lh "${OUTPUT_MSI}"
else
  echo "ERROR: MSI was not created"
  ls -la "${MSI_DIR}/"
  exit 1
fi

# Clean up
rm -rf "${TEMP_DIR}"
