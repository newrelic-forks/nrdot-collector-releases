#!/bin/bash
set -e

VERSION="1.11.1.0"
PRODUCT_CODE="12345678-9ABC-DEF0-1234-567890ABCDEF"
UPGRADE_CODE="A1B2C3D4-E5F6-7890-ABCD-EF1234567890"
BINARY_PATH="dist/nrdot-collector-host_windows_amd64_v1/nrdot-collector-host.exe"
CONFIG_PATH="distributions/nrdot-collector-host/config.yaml"
OUTPUT_MSI="binaries/nrdot-collector-host_1.11.1-SNAPSHOT-c403bb8_windows_amd64.msi"

echo "Building MSI installer for Windows AMD64..."

# Create temporary directory
TEMP_DIR=$(mktemp -d)
cd "${TEMP_DIR}"

# Create directory structure
mkdir -p files

# Copy files
cp "/workspace/${BINARY_PATH}" files/
cp "/workspace/${CONFIG_PATH}" files/

# First create empty MSI database
msibuild output.msi -s "NRDOT Collector Host" "New Relic"

# Create Property table
cat > Property.idt << EOF
Property	Value
s72	l0
Property	Property
ProductCode	{${PRODUCT_CODE}}
ProductLanguage	1033
ProductName	NRDOT Collector Host
ProductVersion	${VERSION}
Manufacturer	New Relic
UpgradeCode	{${UPGRADE_CODE}}
ARPPRODUCTICON	nrdot-collector-host.exe
INSTALLFOLDER	[ProgramFilesFolder]NRDOT Collector Host
EOF

# Create Directory table
cat > Directory.idt << 'EOF'
Directory	Directory_Parent	DefaultDir
s72	S72	l255
Directory	Directory
TARGETDIR		SourceDir
ProgramFilesFolder	TARGETDIR	.
INSTALLFOLDER	ProgramFilesFolder	NRDOT~1|NRDOT Collector Host
EOF

# Create Component table
cat > Component.idt << 'EOF'
Component	ComponentId	Directory_	Attributes	Condition	KeyPath
s72	S38	s72	i2	S255	S72
Component	Component
MainExecutable	{12345678-ABCD-EF12-3456-789ABCDEF012}	INSTALLFOLDER	0		FileMain
ConfigFile	{23456789-BCDE-F123-4567-89ABCDEF0123}	INSTALLFOLDER	0		FileConfig
EOF

# Create Feature table
cat > Feature.idt << 'EOF'
Feature	Feature_Parent	Title	Description	Display	Level	Directory_	Attributes
s38	S38	L64	L255	I2	i2	S72	i2
Feature	Feature
Complete		NRDOT Collector Host	Complete installation	1	3	INSTALLFOLDER	0
EOF

# Create FeatureComponents table
cat > FeatureComponents.idt << 'EOF'
Feature_	Component_
s38	s72
FeatureComponents	Feature_	Component_
Complete	MainExecutable
Complete	ConfigFile
EOF

# Create File table
cat > File.idt << 'EOF'
File	Component_	FileName	FileSize	Version	Language	Attributes	Sequence
s72	s72	l255	i4	S72	S20	I2	i2
File	File
FileMain	MainExecutable	nrdot-collector-host.exe	134217728			512	1
FileConfig	ConfigFile	config.yaml	4096			512	2
EOF

# Create Media table
cat > Media.idt << 'EOF'
DiskId	LastSequence	DiskPrompt	Cabinet	VolumeLabel	Source
i2	i4	L64	S255	S32	S72
Media	DiskId
1	2		#files.cab
EOF

# Import tables
msibuild output.msi -i Property.idt
msibuild output.msi -i Directory.idt
msibuild output.msi -i Component.idt
msibuild output.msi -i Feature.idt
msibuild output.msi -i FeatureComponents.idt
msibuild output.msi -i File.idt
msibuild output.msi -i Media.idt

# Create cabinet file with gcab
cd files
if command -v gcab &> /dev/null; then
    gcab -c files.cab nrdot-collector-host.exe config.yaml
elif command -v lcab &> /dev/null; then
    lcab nrdot-collector-host.exe config.yaml files.cab
else
    echo "ERROR: No cabinet tool found (gcab or lcab required)"
    exit 1
fi
cd ..

# Add cabinet to MSI
msibuild output.msi -a files.cab files/files.cab

# Copy MSI to output
mkdir -p /workspace/binaries
cp output.msi "/workspace/${OUTPUT_MSI}"

echo "MSI created successfully: ${OUTPUT_MSI}"
ls -lh "/workspace/${OUTPUT_MSI}"

# Clean up
cd /workspace
rm -rf "${TEMP_DIR}"
