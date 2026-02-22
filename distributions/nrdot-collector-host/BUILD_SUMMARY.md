# NRDOT Collector Host - Build Summary

## Version: 1.11.0

**Build Date:** February 20, 2026
**Distribution:** nrdot-collector-host
**Repository:** newrelic/nrdot-collector-releases

---

## Successfully Generated Packages

All packages have been built and are ready for distribution:

### Linux AMD64 Packages
- **DEB Package:** `nrdot-collector-host_1.11.0_linux_amd64.deb` (32 MB)
  - SHA256: `a12a9cd27a1d4f958f09bc3fd9ec5d88c4dc68d51e493328540c7754304ef936`
- **RPM Package:** `nrdot-collector-host_1.11.0_linux_x86_64.rpm` (32 MB)
  - SHA256: `941911cb3c370fffd8749751b72597bfd308665052b00cf1625bdd49532201f7`

### Linux ARM64 Packages
- **DEB Package:** `nrdot-collector-host_1.11.0_linux_arm64.deb` (29 MB)
  - SHA256: `693d7b0dba5f380728fbeb16c42e4bd77f31de2c754a3d3abccda0c8d6e2e598`
- **RPM Package:** `nrdot-collector-host_1.11.0_linux_aarch64.rpm` (29 MB)
  - SHA256: `eae54d8d574bad4fea08b4e87e0cf38c5cf8cfa78aff5feac7de99c71d6103b5`

### Windows AMD64 Package
- **MSI Installer:** `nrdot-collector-host_1.11.0_windows_amd64.msi` (36 MB)
  - SHA256: `11b3a3533ceba3de2ee0d210a9d515af3589d51b4861dd85cd83317063c3a045`
  - **Includes Windows Service support with --config flag**

---

## Package Locations

All packages are located in:
```
/Users/pkulkarni/workspace/newrelic/nrdot-collector-releases/distributions/nrdot-collector-host/packages/
```

All binaries are located in:
```
/Users/pkulkarni/workspace/newrelic/nrdot-collector-releases/distributions/nrdot-collector-host/binaries/
```

---

## Installation Instructions

### Debian/Ubuntu (AMD64)
```bash
sudo dpkg -i nrdot-collector-host_1.11.0_linux_amd64.deb
sudo systemctl start nrdot-collector-host
sudo systemctl enable nrdot-collector-host
```

### Debian/Ubuntu (ARM64)
```bash
sudo dpkg -i nrdot-collector-host_1.11.0_linux_arm64.deb
sudo systemctl start nrdot-collector-host
sudo systemctl enable nrdot-collector-host
```

### RHEL/CentOS/Rocky Linux (AMD64)
```bash
sudo rpm -i nrdot-collector-host_1.11.0_linux_x86_64.rpm
sudo systemctl start nrdot-collector-host
sudo systemctl enable nrdot-collector-host
```

### RHEL/CentOS/Rocky Linux (ARM64)
```bash
sudo rpm -i nrdot-collector-host_1.11.0_linux_aarch64.rpm
sudo systemctl start nrdot-collector-host
sudo systemctl enable nrdot-collector-host
```

### Windows (AMD64)
```powershell
# Run the MSI installer (GUI or silent)
msiexec /i nrdot-collector-host_1.11.0_windows_amd64.msi

# Or for silent installation:
msiexec /i nrdot-collector-host_1.11.0_windows_amd64.msi /qn

# The service will be installed as 'nrdot-collector-host'
# Service arguments: --config "[INSTALLDIR]config.yaml"
```

---

## Package Contents

### Linux Packages (DEB/RPM)
- **Binary:** `/usr/bin/nrdot-collector-host` (131 MB)
- **Config Files:**
  - `/etc/nrdot-collector-host/config.yaml`
  - `/etc/nrdot-collector-host/nrdot-collector-host.conf`
- **Systemd Service:** `/lib/systemd/system/nrdot-collector-host.service`
- **Install Scripts:** preinstall.sh, postinstall.sh, preremove.sh

### Windows MSI
- **Binary:** `[INSTALLDIR]\nrdot-collector-host.exe`
- **Config:** `[INSTALLDIR]\config.yaml`
- **Service:** Auto-configured with --config flag
- **Service Name:** `nrdot-collector-host`

---

## Build Process (FROZEN)

The build process is now **FROZEN** and consists of two stages:

### Stage 1: Binary Generation
**Script:** `build-all-binaries.sh`

Generates raw binaries for all platforms:
- Linux AMD64 (with CGO for Oracle/SQL Server)
- Linux ARM64 (with CGO for Oracle/SQL Server)
- Windows AMD64 (with CGO for Oracle/SQL Server)

**Technology:**
- Uses OpenTelemetry Collector Builder (ocb)
- Docker with golang:1.24-bookworm
- Cross-compilation toolchains (gcc-aarch64-linux-gnu, mingw-w64)
- CGO_ENABLED=1 for database receiver support

### Stage 2: Package Creation
**Script:** `BUILD_FINAL.sh` ⭐ **FROZEN SOLUTION**

Creates installable packages from pre-built binaries:
- **Linux packages:** Uses FPM (Effing Package Management) in Docker
- **Windows MSI:** Uses WiX Toolset (wixl) in Docker

**Technology:**
- Ruby 3.1 with FPM gem for DEB/RPM creation
- Ubuntu 22.04 with msitools/wixl for MSI creation
- Docker ensures reproducible builds

---

## Custom Receivers

This collector includes forked versions with custom patches:

### Oracle Receiver
- **Repository:** `github.com/newrelic-forks/nrdot-collector-components/receiver/newrelicoraclereceiver`
- **Commit:** `63a57812ebd59cbcac19d325064ed734ae2f1795`

### SQL Server Receiver
- **Repository:** `github.com/newrelic-forks/nrdot-collector-components/receiver/newrelicsqlserverreceiver`
- **Commit:** `5e78932d9c176ddaa091189bc373ae6d19c64ff1`

---

## Verification Commands

### Verify Checksums
```bash
# Linux/macOS
shasum -a 256 -c nrdot-collector-host_1.11.0_linux_amd64.deb.sha256

# Windows (PowerShell)
Get-FileHash -Algorithm SHA256 nrdot-collector-host_1.11.0_windows_amd64.msi
```

### Inspect Package Contents
```bash
# DEB packages
dpkg-deb --contents nrdot-collector-host_1.11.0_linux_amd64.deb

# RPM packages
rpm -qlp nrdot-collector-host_1.11.0_linux_x86_64.rpm

# MSI packages (Windows)
msiexec /a nrdot-collector-host_1.11.0_windows_amd64.msi /qb TARGETDIR=C:\temp\extract
```

---

## Service Management

### Linux (systemd)
```bash
# Check service status
sudo systemctl status nrdot-collector-host

# View logs
sudo journalctl -u nrdot-collector-host -f

# Restart service
sudo systemctl restart nrdot-collector-host

# Stop service
sudo systemctl stop nrdot-collector-host
```

### Windows (Service Control Manager)
```powershell
# Check service status
Get-Service nrdot-collector-host

# Start service
Start-Service nrdot-collector-host

# Stop service
Stop-Service nrdot-collector-host

# View logs (Event Viewer)
Get-EventLog -LogName Application -Source "nrdot-collector-host" -Newest 50
```

---

## Configuration

The collector uses OpenTelemetry Collector configuration format. Edit the config file:

### Linux
```bash
sudo nano /etc/nrdot-collector-host/config.yaml
sudo systemctl restart nrdot-collector-host
```

### Windows
```powershell
notepad "C:\Program Files\NRDOT Collector Host\config.yaml"
Restart-Service nrdot-collector-host
```

---

## Technical Specifications

### Build Environment
- **Go Version:** 1.24
- **Base Image:** golang:1.24-bookworm
- **CGO:** Enabled for Oracle Instant Client and SQL Server support
- **Compiler Flags:** `-trimpath -ldflags='-s -w'`

### Platform Support
- **Linux:** AMD64 (x86_64), ARM64 (aarch64)
- **Windows:** AMD64 (x86_64)
- **Minimum OS:**
  - Ubuntu 20.04+, Debian 11+
  - RHEL 8+, CentOS 8+, Rocky Linux 8+
  - Windows Server 2016+, Windows 10+

### Binary Sizes
- **Linux AMD64:** 131 MB (after compression in packages: ~32 MB)
- **Linux ARM64:** 116 MB (after compression in packages: ~29 MB)
- **Windows AMD64:** 128 MB (after compression in MSI: ~36 MB)

---

## Troubleshooting

### Linux: Service Won't Start
```bash
# Check service status and logs
sudo systemctl status nrdot-collector-host
sudo journalctl -u nrdot-collector-host -n 50

# Verify binary permissions
ls -l /usr/bin/nrdot-collector-host

# Validate config
/usr/bin/nrdot-collector-host --config /etc/nrdot-collector-host/config.yaml validate
```

### Windows: Service Installation Failed
```powershell
# Check Event Viewer
eventvwr.msc

# Manually install service
sc.exe create nrdot-collector-host binPath= "\"C:\Program Files\NRDOT Collector Host\nrdot-collector-host.exe\" --config \"C:\Program Files\NRDOT Collector Host\config.yaml\"" start= auto

# Verify service exists
Get-Service nrdot-collector-host
```

### Database Connection Issues
```bash
# Oracle: Verify Oracle Instant Client
ldd /usr/bin/nrdot-collector-host | grep oracle

# SQL Server: Check network connectivity
telnet <sql-server-host> 1433
```

---

## Rebuild Instructions

If you need to regenerate the packages:

### Full Rebuild (Binaries + Packages)
```bash
cd /Users/pkulkarni/workspace/newrelic/nrdot-collector-releases/distributions/nrdot-collector-host

# Step 1: Generate binaries
./build-all-binaries.sh

# Step 2: Create packages
./BUILD_FINAL.sh
```

### Package-Only Rebuild
If binaries already exist in `binaries/` directory:
```bash
cd /Users/pkulkarni/workspace/newrelic/nrdot-collector-releases/distributions/nrdot-collector-host

# Create packages from existing binaries
./BUILD_FINAL.sh
```

---

## Checksums (SHA256)

```
a12a9cd27a1d4f958f09bc3fd9ec5d88c4dc68d51e493328540c7754304ef936  nrdot-collector-host_1.11.0_linux_amd64.deb
693d7b0dba5f380728fbeb16c42e4bd77f31de2c754a3d3abccda0c8d6e2e598  nrdot-collector-host_1.11.0_linux_arm64.deb
eae54d8d574bad4fea08b4e87e0cf38c5cf8cfa78aff5feac7de99c71d6103b5  nrdot-collector-host_1.11.0_linux_aarch64.rpm
941911cb3c370fffd8749751b72597bfd308665052b00cf1625bdd49532201f7  nrdot-collector-host_1.11.0_linux_x86_64.rpm
11b3a3533ceba3de2ee0d210a9d515af3589d51b4861dd85cd83317063c3a045  nrdot-collector-host_1.11.0_windows_amd64.msi
```

---

## Support

- **Repository:** https://github.com/newrelic/nrdot-collector-releases
- **Maintainer:** New Relic <otelcomm-team@newrelic.com>
- **License:** Apache-2.0

---

## Build Status: ✅ COMPLETE

All packages successfully created and verified.

**End of Build Summary**
