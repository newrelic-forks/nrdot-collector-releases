# FROZEN BUILD CONTEXT - NRDOT Collector Host
## DO NOT MODIFY - Production-Ready Build System

---

## 🔒 FROZEN VERSION: 1.11.0
**Last Updated:** February 20, 2026
**Status:** PRODUCTION READY - DO NOT CHANGE

---

## Quick Rebuild Command

To regenerate all packages exactly as they are now, use this single prompt:

```
Rebuild all nrdot-collector-host packages using the frozen build scripts.
Run build-all-binaries.sh first, then BUILD_FINAL.sh
```

---

## Two-Step Build Process (FROZEN)

### Step 1: Generate Binaries
```bash
cd /Users/pkulkarni/workspace/newrelic/nrdot-collector-releases/distributions/nrdot-collector-host
./build-all-binaries.sh
```

**What it does:**
- Runs OpenTelemetry Collector Builder (ocb) to generate custom collector code
- Builds Linux AMD64 binary (with CGO for Oracle/SQL Server)
- Builds Linux ARM64 binary (with CGO for Oracle/SQL Server)
- Builds Windows AMD64 binary (with CGO for Oracle/SQL Server)
- Generates SHA256 checksums for all binaries
- Output: `binaries/` directory with all platform binaries

**Technology Stack:**
- Docker with golang:1.24-bookworm
- CGO_ENABLED=1
- Cross-compilation toolchains:
  - `gcc-aarch64-linux-gnu` for ARM64
  - `x86_64-w64-mingw32-gcc` for Windows
- Compiler flags: `-trimpath -ldflags='-s -w'`

### Step 2: Create Packages
```bash
cd /Users/pkulkarni/workspace/newrelic/nrdot-collector-releases/distributions/nrdot-collector-host
./BUILD_FINAL.sh
```

**What it does:**
- Creates DEB packages for Linux AMD64 and ARM64
- Creates RPM packages for Linux AMD64 and ARM64
- Creates MSI installer for Windows AMD64 with service support
- Generates SHA256 checksums for all packages
- Output: `packages/` directory with all installable packages

**Technology Stack:**
- FPM (Effing Package Management) via Docker ruby:3.1-slim
- WiX Toolset (wixl) via Docker ubuntu:22.04
- Includes systemd service files, config files, install scripts

---

## File Locations (FROZEN)

### Build Scripts
```
/Users/pkulkarni/workspace/newrelic/nrdot-collector-releases/distributions/nrdot-collector-host/
├── build-all-binaries.sh    ← Step 1: Binary generation
├── BUILD_FINAL.sh            ← Step 2: Package creation (FROZEN)
├── BUILD_SUMMARY.md          ← Complete documentation
└── FROZEN_BUILD_CONTEXT.md   ← This file
```

### Build Artifacts
```
/Users/pkulkarni/workspace/newrelic/nrdot-collector-releases/distributions/nrdot-collector-host/
├── binaries/                 ← Raw binaries (Step 1 output)
│   ├── nrdot-collector-host-linux-amd64
│   ├── nrdot-collector-host-linux-arm64
│   └── nrdot-collector-host-windows-amd64.exe
│
├── packages/                 ← Installable packages (Step 2 output)
│   ├── nrdot-collector-host_1.11.0_linux_amd64.deb
│   ├── nrdot-collector-host_1.11.0_linux_x86_64.rpm
│   ├── nrdot-collector-host_1.11.0_linux_arm64.deb
│   ├── nrdot-collector-host_1.11.0_linux_aarch64.rpm
│   └── nrdot-collector-host_1.11.0_windows_amd64.msi
│
└── _build/                   ← Generated collector code (temporary)
```

### Configuration Files
```
/Users/pkulkarni/workspace/newrelic/nrdot-collector-releases/distributions/nrdot-collector-host/
├── manifest.yaml             ← Collector component definitions
├── config.yaml               ← Runtime configuration (included in packages)
├── nrdot-collector-host.conf ← Environment variables (included in packages)
├── nrdot-collector-host.service ← Systemd service file (included in packages)
├── preinstall.sh             ← Pre-installation script
├── postinstall.sh            ← Post-installation script
└── preremove.sh              ← Pre-removal script
```

---

## Package Specifications (FROZEN)

### Linux DEB/RPM Packages
- **Package Name:** nrdot-collector-host
- **Version:** 1.11.0
- **Architecture:** amd64 (x86_64), arm64 (aarch64)
- **Description:** NRDOT Collector Host with Oracle and SQL Server support
- **URL:** https://github.com/newrelic/nrdot-collector-releases
- **License:** Apache-2.0
- **Maintainer:** New Relic <otelcomm-team@newrelic.com>

**Contents:**
- `/usr/bin/nrdot-collector-host` (executable binary)
- `/etc/nrdot-collector-host/config.yaml` (config file)
- `/etc/nrdot-collector-host/nrdot-collector-host.conf` (environment file)
- `/lib/systemd/system/nrdot-collector-host.service` (systemd service)

### Windows MSI Installer
- **Product Name:** NRDOT Collector Host
- **Version:** 1.11.0
- **Architecture:** amd64 (x86_64)
- **Upgrade Code:** 12345678-1234-1234-1234-123456789012 (FROZEN)
- **Manufacturer:** New Relic

**Contents:**
- `[INSTALLDIR]\nrdot-collector-host.exe` (executable binary)
- `[INSTALLDIR]\config.yaml` (config file)

**Service Configuration:**
- **Service Name:** nrdot-collector-host
- **Display Name:** NRDOT Collector Host
- **Description:** New Relic NRDOT Collector with Oracle and SQL Server monitoring
- **Start Type:** Automatic
- **Service Account:** LocalSystem
- **Service Arguments:** `--config "[INSTALLDIR]config.yaml"`

---

## Custom Receivers (FROZEN)

### Oracle Receiver
- **Repository:** github.com/newrelic-forks/nrdot-collector-components/receiver/newrelicoraclereceiver
- **Commit Hash:** 63a57812ebd59cbcac19d325064ed734ae2f1795
- **Defined in:** manifest.yaml

### SQL Server Receiver
- **Repository:** github.com/newrelic-forks/nrdot-collector-components/receiver/newrelicsqlserverreceiver
- **Commit Hash:** 5e78932d9c176ddaa091189bc373ae6d19c64ff1
- **Defined in:** manifest.yaml

---

## Expected Build Output

### Binaries (Step 1)
```
binaries/nrdot-collector-host-linux-amd64         (125 MB, ELF 64-bit LSB, x86-64)
binaries/nrdot-collector-host-linux-arm64         (116 MB, ELF 64-bit LSB, ARM aarch64)
binaries/nrdot-collector-host-windows-amd64.exe   (128 MB, PE32+ x86-64)
```

### Packages (Step 2)
```
packages/nrdot-collector-host_1.11.0_linux_amd64.deb        (32 MB)
packages/nrdot-collector-host_1.11.0_linux_x86_64.rpm       (32 MB)
packages/nrdot-collector-host_1.11.0_linux_arm64.deb        (29 MB)
packages/nrdot-collector-host_1.11.0_linux_aarch64.rpm      (29 MB)
packages/nrdot-collector-host_1.11.0_windows_amd64.msi      (36 MB)
```

All with corresponding `.sha256` checksum files.

---

## Build Time Estimates

- **Step 1 (Binaries):** ~15-20 minutes
  - OCB generation: ~2 minutes
  - Linux AMD64: ~5 minutes
  - Linux ARM64: ~5 minutes
  - Windows AMD64: ~5 minutes

- **Step 2 (Packages):** ~5-8 minutes
  - DEB/RPM creation: ~3 minutes
  - MSI creation: ~2 minutes
  - Checksums: ~1 minute

**Total Build Time:** ~20-30 minutes

---

## System Requirements

### Build Machine (macOS/Linux)
- Docker Desktop installed and running
- At least 10 GB free disk space
- Internet connection (for Docker image pulls)

### Docker Images Used
- `golang:1.24-bookworm` (for binary compilation)
- `ruby:3.1-slim` (for FPM package creation)
- `ubuntu:22.04` (for MSI creation with wixl)

---

## Verification Commands

### After Step 1 (Binaries)
```bash
# List generated binaries
ls -lh binaries/

# Verify binary types
file binaries/nrdot-collector-host-linux-amd64
file binaries/nrdot-collector-host-linux-arm64
file binaries/nrdot-collector-host-windows-amd64.exe

# Check SHA256 checksums
cat binaries/*.sha256
```

### After Step 2 (Packages)
```bash
# List generated packages
ls -lh packages/

# Verify DEB package contents
docker run --rm -v "$(pwd)/packages:/packages" ubuntu:22.04 \
  dpkg-deb --contents /packages/nrdot-collector-host_1.11.0_linux_amd64.deb

# Verify checksums
shasum -a 256 -c packages/nrdot-collector-host_1.11.0_linux_amd64.deb.sha256
```

---

## Troubleshooting

### Issue: Docker image pull fails
**Solution:** Check internet connection and Docker daemon status
```bash
docker ps
docker pull golang:1.24-bookworm
```

### Issue: Build scripts not executable
**Solution:** Add execute permissions
```bash
chmod +x build-all-binaries.sh BUILD_FINAL.sh
```

### Issue: "binaries directory not found" in Step 2
**Solution:** Run Step 1 first
```bash
./build-all-binaries.sh
```

### Issue: Out of disk space
**Solution:** Clean up Docker cache and old builds
```bash
docker system prune -a
rm -rf _build/ binaries/ packages/
```

---

## Git Branch Information

- **Current Branch:** feature/sqlserver-oracle-receivers
- **Main Branch:** main
- **Modified Files:**
  - distributions/nrdot-collector-host/.goreleaser-cgo-enabled.yaml
  - distributions/nrdot-collector-host/manifest.yaml

---

## Simple Rebuild Prompts for Claude

Use any of these prompts to trigger a complete rebuild:

### Prompt 1 (Recommended)
```
Rebuild all nrdot-collector-host packages using the frozen build scripts.
Run build-all-binaries.sh first, then BUILD_FINAL.sh
```

### Prompt 2 (Detailed)
```
I need to regenerate all nrdot-collector-host v1.11.0 packages.
Execute the frozen build process:
1. Run build-all-binaries.sh to generate binaries
2. Run BUILD_FINAL.sh to create packages
Follow the exact process documented in FROZEN_BUILD_CONTEXT.md
```

### Prompt 3 (Quick)
```
Run the frozen NRDOT build: ./build-all-binaries.sh && ./BUILD_FINAL.sh
```

### Prompt 4 (With verification)
```
Rebuild nrdot-collector-host packages using frozen scripts.
After completion, verify all 5 packages and their checksums are generated.
```

---

## Expected SHA256 Checksums (Reference)

These checksums are from the frozen build on February 20, 2026:

```
a12a9cd27a1d4f958f09bc3fd9ec5d88c4dc68d51e493328540c7754304ef936  nrdot-collector-host_1.11.0_linux_amd64.deb
693d7b0dba5f380728fbeb16c42e4bd77f31de2c754a3d3abccda0c8d6e2e598  nrdot-collector-host_1.11.0_linux_arm64.deb
eae54d8d574bad4fea08b4e87e0cf38c5cf8cfa78aff5feac7de99c71d6103b5  nrdot-collector-host_1.11.0_linux_aarch64.rpm
941911cb3c370fffd8749751b72597bfd308665052b00cf1625bdd49532201f7  nrdot-collector-host_1.11.0_linux_x86_64.rpm
11b3a3533ceba3de2ee0d210a9d515af3589d51b4861dd85cd83317063c3a045  nrdot-collector-host_1.11.0_windows_amd64.msi
```

Note: Checksums may vary slightly between builds due to timestamps and build metadata.

---

## DO NOT MODIFY

This build system is **FROZEN** and production-ready. Do not modify:
- build-all-binaries.sh
- BUILD_FINAL.sh
- manifest.yaml (except for version bumps)
- Package structure or contents
- Service configuration

Only modify:
- config.yaml (for collector configuration changes)
- Version number in manifest.yaml (for new releases)

---

## Support

- **Repository:** https://github.com/newrelic/nrdot-collector-releases
- **Maintainer:** New Relic <otelcomm-team@newrelic.com>
- **License:** Apache-2.0

---

**END OF FROZEN BUILD CONTEXT**

This document ensures reproducible builds. Keep it with your build scripts.
