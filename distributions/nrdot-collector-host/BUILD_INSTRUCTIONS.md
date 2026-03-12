# NRDOT Collector Host - Build Instructions

**Last Updated**: March 11, 2026
**Version**: 1.11.0

## Build Configuration

### Current Commit Hashes
- **Oracle DB Receiver**: `1b695b05898264665921332814fbfec3b332b8ab`
- **SQL Server Receiver**: `5f3a23f69c07ccd3405c900bce94a239c537ab4d`

These commits are configured in `manifest.yaml` (lines 51-54):
```yaml
replaces:
  # Replace with custom oracle receiver from fork (commit 1b695b05898264665921332814fbfec3b332b8ab)
  - github.com/open-telemetry/opentelemetry-collector-contrib/receiver/newrelicoraclereceiver => github.com/newrelic-forks/nrdot-collector-components/receiver/newrelicoraclereceiver 1b695b05898264665921332814fbfec3b332b8ab
  # Replace with custom sqlserver receiver from fork (commit 5f3a23f69c07ccd3405c900bce94a239c537ab4d)
  - github.com/open-telemetry/opentelemetry-collector-contrib/receiver/newrelicsqlserverreceiver => github.com/newrelic-forks/nrdot-collector-components/receiver/newrelicsqlserverreceiver 5f3a23f69c07ccd3405c900bce94a239c537ab4d
```

### Build Flags
- **CGO_ENABLED**: `1` (required for Oracle and SQL Server database drivers)
- **buildmode**: `pie` (Position Independent Executable for security)

### Platform Requirements
- Docker must be running (required for cross-compilation)
- Rancher Desktop or Docker Desktop

## Build Process

### Step 1: Clean Previous Builds
```bash
rm -rf _build dist packages binaries
```

### Step 2: Run Complete Build
```bash
bash build-all-packages.sh
```

This script will:
1. Generate OpenTelemetry collector sources using `ocb` (OpenTelemetry Collector Builder)
2. Build Linux AMD64 binary (139M) with CGO and buildmode=pie
3. Build Linux ARM64 binary (130M) with CGO and buildmode=pie
4. Build Windows AMD64 binary (128M) with CGO and buildmode=pie
5. Create AMD64 DEB and RPM packages

### Step 3: Create ARM64 Packages
```bash
docker run --rm \
  -v "$(pwd):/workspace" \
  -w /workspace \
  goreleaser/nfpm:latest \
  package --config nfpm-arm64.yaml --packager deb --target /workspace/packages

docker run --rm \
  -v "$(pwd):/workspace" \
  -w /workspace \
  goreleaser/nfpm:latest \
  package --config nfpm-arm64.yaml --packager rpm --target /workspace/packages
```

### Step 4: Prepare Windows Binary
```bash
mkdir -p binaries
cp dist/nrdot-collector-host_windows_amd64_v1/nrdot-collector-host.exe \
   binaries/nrdot-collector-host-windows-amd64.exe
```

### Step 5: Build Windows MSI
```bash
bash build-msi-improved.sh
```

### Step 6: Generate SHA256 Checksums
```bash
cd packages
shasum -a 256 nrdot-collector-host_1.11.0_amd64.deb > nrdot-collector-host_1.11.0_amd64.deb.sha256
shasum -a 256 nrdot-collector-host-1.11.0-1.x86_64.rpm > nrdot-collector-host-1.11.0-1.x86_64.rpm.sha256
shasum -a 256 nrdot-collector-host_1.11.0_arm64.deb > nrdot-collector-host_1.11.0_arm64.deb.sha256
shasum -a 256 nrdot-collector-host-1.11.0-1.aarch64.rpm > nrdot-collector-host-1.11.0-1.aarch64.rpm.sha256
shasum -a 256 nrdot-collector-host_1.11.0_windows_amd64_improved.msi > nrdot-collector-host_1.11.0_windows_amd64_improved.msi.sha256
```

## Expected Output

### Binaries Location
- Linux AMD64: `dist/nrdot-collector-host_linux_amd64_v1/nrdot-collector-host`
- Linux ARM64: `dist/nrdot-collector-host_linux_arm64/nrdot-collector-host`
- Windows AMD64: `dist/nrdot-collector-host_windows_amd64_v1/nrdot-collector-host.exe`

### Package Outputs

**Linux AMD64:**
- `packages/nrdot-collector-host_1.11.0_amd64.deb` (~35M)
- `packages/nrdot-collector-host-1.11.0-1.x86_64.rpm` (~37M)

**Linux ARM64:**
- `packages/nrdot-collector-host_1.11.0_arm64.deb` (~32M)
- `packages/nrdot-collector-host-1.11.0-1.aarch64.rpm` (~33M)

**Windows AMD64:**
- `packages/nrdot-collector-host_1.11.0_windows_amd64_improved.msi` (~43M)
  - Includes MinGW runtime DLLs: libgcc_s_seh-1.dll, libwinpthread-1.dll, libstdc++-6.dll

### Latest Build Checksums (March 11, 2026)
```
9ffb34ba179230ebfa38aad2961cb65a17f094f9e419dab737b8326665c35ac6  nrdot-collector-host_1.11.0_amd64.deb
e33118e97425875d06852d39acf2d0baeef4c2acc9534a14b18a3c7d4f40c527  nrdot-collector-host_1.11.0_arm64.deb
b061ba87d50a026d02f99d0db49325c5d304fd60a2d178e808ec75e35f126a3f  nrdot-collector-host_1.11.0_windows_amd64_improved.msi
5b71e69a7be98a9b9d61c26ee94cbac72171417d7d414e37100fdee885fc8396  nrdot-collector-host-1.11.0-1.aarch64.rpm
c5cad3114919e9e49001e37b5754530786a15c2c74cb9d6b890a566cd0a2cb10  nrdot-collector-host-1.11.0-1.x86_64.rpm
```

## Linux Package Features

### Automatic Service Management
The DEB and RPM packages include automatic systemd service management via `postinstall.sh` (lines 43-46):

```bash
if command -v systemctl >/dev/null 2>&1; then
    systemctl enable nrdot-collector-host.service
    if [ -f /etc/nrdot-collector-host/config.yaml ]; then
        systemctl start nrdot-collector-host.service
    fi
fi
```

**No manual commands needed:**
- ✅ Service is automatically enabled on boot
- ✅ Service is automatically started after installation (if config exists)
- ❌ No need to run: `sudo systemctl enable nrdot-collector-host`
- ❌ No need to run: `sudo systemctl start nrdot-collector-host`

## Docker Build Details

### Linux AMD64 Build
```bash
docker run --rm \
    -v "${BUILD_DIR}:/workspace" \
    -v "${DIST_DIR}:/dist" \
    -w /workspace \
    --platform linux/amd64 \
    golang:1.24-bookworm \
    bash -c "
        apt-get update -qq > /dev/null 2>&1
        apt-get install -y -qq gcc g++ > /dev/null 2>&1
        export CGO_ENABLED=1
        export GOOS=linux
        export GOARCH=amd64
        go build -trimpath -buildmode=pie -ldflags='-s -w' \
            -o /dist/nrdot-collector-host_linux_amd64_v1/nrdot-collector-host .
        chmod +x /dist/nrdot-collector-host_linux_amd64_v1/nrdot-collector-host
    "
```

### Linux ARM64 Build
```bash
docker run --rm \
    -v "${BUILD_DIR}:/workspace" \
    -v "${DIST_DIR}:/dist" \
    -w /workspace \
    --platform linux/amd64 \
    golang:1.24-bookworm \
    bash -c "
        apt-get update -qq > /dev/null 2>&1
        apt-get install -y -qq gcc-aarch64-linux-gnu g++-aarch64-linux-gnu > /dev/null 2>&1
        export CGO_ENABLED=1
        export GOOS=linux
        export GOARCH=arm64
        export CC=aarch64-linux-gnu-gcc
        export CXX=aarch64-linux-gnu-g++
        go build -trimpath -buildmode=pie -ldflags='-s -w' \
            -o /dist/nrdot-collector-host_linux_arm64/nrdot-collector-host .
        chmod +x /dist/nrdot-collector-host_linux_arm64/nrdot-collector-host
    "
```

### Windows AMD64 Build
```bash
docker run --rm \
    -v "${BUILD_DIR}:/workspace" \
    -v "${DIST_DIR}:/dist" \
    -w /workspace \
    --platform linux/amd64 \
    golang:1.24-bookworm \
    bash -c "
        apt-get update -qq > /dev/null 2>&1
        apt-get install -y -qq gcc-mingw-w64-x86-64 g++-mingw-w64-x86-64 > /dev/null 2>&1
        export CGO_ENABLED=1
        export GOOS=windows
        export GOARCH=amd64
        export CC=x86_64-w64-mingw32-gcc
        export CXX=x86_64-w64-mingw32-g++
        go build -trimpath -buildmode=pie -ldflags='-s -w' \
            -o /dist/nrdot-collector-host_windows_amd64_v1/nrdot-collector-host.exe .
    "
```

## Troubleshooting

### Build Script Validation Failure
If you see `❌ Failed to create Linux AMD64 packages`, check if packages were actually created:
```bash
ls -lh packages/
```
The packages may be created successfully despite the validation error.

### Missing Windows Binary
If `build-msi-improved.sh` fails with "Windows binary not found", copy it manually:
```bash
mkdir -p binaries
cp dist/nrdot-collector-host_windows_amd64_v1/nrdot-collector-host.exe \
   binaries/nrdot-collector-host-windows-amd64.exe
```

### Shell Environment Warnings
Warnings about gvm (Go Version Manager) functions can be safely ignored:
```
cd:1: command not found: __gvm_is_function
```
These don't affect the build process.

## Quick Reference Commands

### Update Commits
Edit `manifest.yaml` lines 51-54 with new commit hashes.

### Full Clean Build
```bash
rm -rf _build dist packages binaries
bash build-all-packages.sh
docker run --rm -v "$(pwd):/workspace" -w /workspace goreleaser/nfpm:latest package --config nfpm-arm64.yaml --packager deb --target /workspace/packages
docker run --rm -v "$(pwd):/workspace" -w /workspace goreleaser/nfpm:latest package --config nfpm-arm64.yaml --packager rpm --target /workspace/packages
mkdir -p binaries && cp dist/nrdot-collector-host_windows_amd64_v1/nrdot-collector-host.exe binaries/nrdot-collector-host-windows-amd64.exe
bash build-msi-improved.sh
cd packages && shasum -a 256 *.deb *.rpm *.msi | tee checksums.txt
```

### Verify Commits in Built Binary
```bash
# Check Go module downloads in build output
grep "go: downloading.*newrelic-forks.*receiver" <build-log>

# Expected output showing correct commits:
# go: downloading github.com/newrelic-forks/.../newrelicoraclereceiver v0.0.0-20260311141642-1b695b058982
# go: downloading github.com/newrelic-forks/.../newrelicsqlserverreceiver v0.0.0-20260311160430-5f3a23f69c07
```

## File Manifest

**Critical Build Files:**
- `manifest.yaml` - Component versions and commit overrides
- `build-all-packages.sh` - Main build script for all binaries
- `build-msi-improved.sh` - Windows MSI creation script
- `nfpm-amd64.yaml` - AMD64 DEB/RPM packaging config
- `nfpm-arm64.yaml` - ARM64 DEB/RPM packaging config
- `postinstall.sh` - Linux post-installation script (systemd setup)
- `preinstall.sh` - Linux pre-installation script
- `preremove.sh` - Linux pre-removal script
- `nrdot-collector-host-improved.wxs` - WiX XML for MSI (generated)

## Notes

1. **CGO Requirement**: CGO is required for Oracle (`godror`) and SQL Server (`go-mssqldb`) database drivers. Cannot be disabled.

2. **buildmode=pie**: Provides security benefits through Address Space Layout Randomization (ASLR).

3. **Docker Platform**: All builds run in Docker with `--platform linux/amd64` for consistency, even when building for other architectures.

4. **Go Version**: Using `golang:1.24-bookworm` Docker image.

5. **Systemd Integration**: Linux packages include full systemd integration with automatic enable/start on installation.

6. **Windows MSI**: Requires administrator elevation and includes MinGW runtime DLLs for C library support.

## Build History

### March 11, 2026 - v1.11.0
- Oracle DB: 1b695b05898264665921332814fbfec3b332b8ab
- SQL Server: 5f3a23f69c07ccd3405c900bce94a239c537ab4d
- Built with CGO_ENABLED=1 and buildmode=pie
- All 5 packages created successfully with checksums
