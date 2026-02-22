#!/bin/bash
set -e

VERSION="1.11.1.0"  # MSI requires numeric version
PRODUCT_CODE=$(uuidgen | tr '[:lower:]' '[:upper:]')
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

# Create Property table
cat > Property.idt << 'EOF'
Property	Value
s72	l0
Property	Property
ProductCode	{PRODUCT_CODE}
ProductLanguage	1033
ProductName	NRDOT Collector Host
ProductVersion	VERSION
Manufacturer	New Relic
UpgradeCode	{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}
ARPPRODUCTICON	MainExecutable
INSTALLFOLDER	C:\Program Files\NRDOT Collector Host
EOF

sed -i "s/PRODUCT_CODE/${PRODUCT_CODE}/g" Property.idt
sed -i "s/VERSION/${VERSION}/g" Property.idt

# Create Directory table
cat > Directory.idt << 'EOF'
Directory	Directory_Parent	DefaultDir
s72	S72	l255
Directory	Directory
TARGETDIR		SourceDir
ProgramFilesFolder	TARGETDIR	.:Progra~1
INSTALLFOLDER	ProgramFilesFolder	NRDOT~1|NRDOT Collector Host
EOF

# Create Component table
cat > Component.idt << 'EOF'
Component	ComponentId	Directory_	Attributes	Condition	KeyPath
s72	S38	s72	i2	S255	S72
Component	Component
MainExecutable	{12345678-ABCD-EF12-3456-789ABCDEF012}	INSTALLFOLDER	0		nrdotcollectorhostEXE
ConfigFile	{23456789-BCDE-F123-4567-89ABCDEF0123}	INSTALLFOLDER	0		configYAML
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
nrdotcollectorhostEXE	MainExecutable	NRDOT-~1.EXE|nrdot-collector-host.exe	0			0	1
configYAML	ConfigFile	CONFIG~1.YAM|config.yaml	0			0	2
EOF

# Create Media table
cat > Media.idt << 'EOF'
DiskId	LastSequence	DiskPrompt	Cabinet	VolumeLabel	Source
i2	i4	L64	S255	S32	S72
Media	DiskId
1	2	Installation Media	#files.cab
EOF

# Create _Validation table (required)
cat > _Validation.idt << 'EOF'
Table	Column	Nullable	MinValue	MaxValue	KeyTable	KeyColumn	Category	Set	Description
s32	s32	s4	I4	I4	S255	I2	S32	S255	S255
_Validation	Table	Column
Property	Property	N					Identifier		Name of property
Property	Value	Y									Any string value
Directory	Directory	N					Identifier		Unique directory identifier
Directory	Directory_Parent	Y		Directory	1	Identifier		Parent directory identifier
Directory	DefaultDir	N					DefaultDir		Default directory name
Component	Component	N					Identifier		Component identifier
Component	ComponentId	Y					GUID		Component GUID
Component	Directory_	N		Directory	1	Identifier		Directory for component
Component	Attributes	N	0	32767				LocalOnly;SourceOnly;Optional;RegistryKeyPath;SharedDllRefCount;Permanent;ODBCDataSource;Transitive;NeverOverwrite;64bit	Component attributes
Component	KeyPath	Y		File;Registry;ODBCDataSource	1	Identifier		Key path
Feature	Feature	N					Identifier		Feature identifier
Feature	Feature_Parent	Y		Feature	1	Identifier		Parent feature
Feature	Title	Y					Text		Short feature title
Feature	Description	Y					Text		Feature description
Feature	Display	Y	0	32767				Expanded;Collapsed;Hidden	Feature display
Feature	Level	N	0	32767				Install level
Feature	Directory_	Y		Directory	1	UpperCase		Directory for feature
Feature	Attributes	N	0	65535				FavorLocal;FavorSource;FollowParent;FavorAdvertise;DisallowAdvertise;UIDisallowAbsent;NoUnsupportedAdvertise	Feature attributes
FeatureComponents	Feature_	N		Feature	1	Identifier		Feature identifier
FeatureComponents	Component_	N		Component	1	Identifier		Component identifier
File	File	N					Identifier		File identifier
File	Component_	N		Component	1	Identifier		Component containing file
File	FileName	N					Filename		File name
File	FileSize	N	0	2147483647				File size
File	Version	Y					Version		File version
File	Language	Y					Language		Language ID
File	Attributes	Y	0	32767				ReadOnly;Hidden;System;Compressed;Encrypted;PatchAdded;NonCompressed	File attributes
File	Sequence	N	1	32767				File sequence
Media	DiskId	N	1	32767				Disk ID
Media	LastSequence	N	0	32767				Last sequence number
Media	DiskPrompt	Y					Text		Disk prompt
Media	Cabinet	Y					Cabinet		Cabinet file name
Media	VolumeLabel	Y					Text		Volume label
Media	Source	Y					Property		Source property
EOF

# Create the MSI database
msibuild output.msi \
  -s "NRDOT Collector Host" "New Relic" \
  -i Property.idt \
  -i Directory.idt \
  -i Component.idt \
  -i Feature.idt \
  -i FeatureComponents.idt \
  -i File.idt \
  -i Media.idt \
  -i _Validation.idt

# Add files to cabinet
cd files
gcab -c files.cab nrdot-collector-host.exe config.yaml
msibuild ../output.msi -a files.cab files.cab
cd ..

# Copy MSI to output
mkdir -p /workspace/binaries
cp output.msi "/workspace/${OUTPUT_MSI}"

echo "MSI created successfully: ${OUTPUT_MSI}"
ls -lh "/workspace/${OUTPUT_MSI}"

# Clean up
cd /workspace
rm -rf "${TEMP_DIR}"
