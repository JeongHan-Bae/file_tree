import sys
import zipfile
import tarfile
import os

# Get Python version
PYTHON_VERSION = f"cp{sys.version_info[0]}{sys.version_info[1]}"

# Directory path constants
INFO_DIR = "INFO"
INCLUDE_DIR = "include"
MAKE_DIR = "make"
OUTPUT_DIR = "wheel"

# Ensure the output directory exists
os.makedirs(OUTPUT_DIR, exist_ok=True)


# Function to get module information from the METADATA file
def GET_INFO(metadata_file):
    module_info = {}
    with open(metadata_file, 'r') as _f:
        for line in _f:
            if line.startswith("Name:"):
                module_info['name'] = line.split("Name:")[1].strip()
            elif line.startswith("Version:"):
                module_info['version'] = line.split("Version:")[1].strip()

    if 'name' not in module_info or 'version' not in module_info:
        raise ValueError("Name or Version not found in metadata")

    return module_info


MODULE_INFO = GET_INFO(f"{INFO_DIR}/METADATA")

MODULE_NAME = MODULE_INFO['name']
MODULE_VERSION = MODULE_INFO['version']

# Determine platform-specific information
if sys.platform == "win32":
    PLATFORM_TAG = "win_amd64"
    EXT = "pyd"
    OS_CLASSIFIER = "Operating System :: Microsoft :: Windows"
elif sys.platform == "darwin":
    PLATFORM_TAG = "macosx_10_9_x86_64"
    EXT = "so"
    OS_CLASSIFIER = "Operating System :: MacOS"
else:  # Assuming Linux for all other cases
    PLATFORM_TAG = "manylinux1_x86_64"
    EXT = "so"
    OS_CLASSIFIER = "Operating System :: POSIX :: Linux"

# Generate WHEEL file content
WHEEL_CONTENT = f"""Wheel-Version: 1.0
Generator: custom-setup-script
Root-Is-Purelib: false
Tag: {PYTHON_VERSION}-{PLATFORM_TAG}
Classifier: Programming Language :: Python :: {sys.version_info[0]}
Classifier: Programming Language :: Python :: {sys.version_info[0]}.{sys.version_info[1]}
Classifier: {OS_CLASSIFIER}
"""

# Write the WHEEL content to a file
with open(f"{INFO_DIR}/WHEEL", "w") as f:
    f.write(WHEEL_CONTENT)

# Generate RECORD file content
RECORD_CONTENT = f"""file_tree.pyi,,
file_tree.{PYTHON_VERSION}-{PLATFORM_TAG}.{EXT},,
file_tree-{MODULE_VERSION}.dist-info/METADATA,,
file_tree-{MODULE_VERSION}.dist-info/WHEEL,,
file_tree-{MODULE_VERSION}.dist-info/RECORD,,
"""

# Write the RECORD content to a file
with open(f"{INFO_DIR}/RECORD", "w") as f:
    f.write(RECORD_CONTENT)

# Define files to be included in the .whl package and their target paths
WHL_FILENAME = f"{OUTPUT_DIR}/{MODULE_NAME}-{MODULE_VERSION}-{PYTHON_VERSION}-{PYTHON_VERSION}-{PLATFORM_TAG}.whl"

WHL_FILES = [
    (f"{INCLUDE_DIR}/{MODULE_NAME}.pyi", f"{MODULE_NAME}.pyi"),
    (f"{MAKE_DIR}/{MODULE_NAME}.{PYTHON_VERSION}-{PLATFORM_TAG}.{EXT}",
     f"{MODULE_NAME}.{PYTHON_VERSION}-{PLATFORM_TAG}.{EXT}"),
    (f"{INFO_DIR}/METADATA", f"{MODULE_NAME}-{MODULE_VERSION}.dist-info/METADATA"),
    (f"{INFO_DIR}/WHEEL", f"{MODULE_NAME}-{MODULE_VERSION}.dist-info/WHEEL"),
    (f"{INFO_DIR}/RECORD", f"{MODULE_NAME}-{MODULE_VERSION}.dist-info/RECORD"),
    ("README.md", "README.md")
]

# Create the .whl file and add files to it
with zipfile.ZipFile(WHL_FILENAME, 'w') as whl:
    for src, dst in WHL_FILES:
        whl.write(src, dst)

print(f"Created {WHL_FILENAME}")

# Generate the .tar.gz file
TAR_GZ_FILENAME = f"{OUTPUT_DIR}/{MODULE_NAME}-{MODULE_VERSION}.tar.gz"
TAR_DIR = f"{MODULE_NAME}-{MODULE_VERSION}"

TOML_FILE = "pyproject.toml"

# Open the .tar.gz file and add files to it
with tarfile.open(TAR_GZ_FILENAME, "w:gz") as tar:
    for src, dst in WHL_FILES:
        tar.add(src, arcname=f"{TAR_DIR}/{dst}")
    tar.add(TOML_FILE, arcname=f"{TAR_DIR}/{TOML_FILE}")
print(f"Created {TAR_GZ_FILENAME}")
