#scripts/build-pypy-sysext.sh
#!/bin/bash
set -euo pipefail # Exit on error, unset variable, or pipe failure

# --- Configuration (Adjust as needed) ---
PYPY_VERSION_ID="3.10-v7.3.15" # PyPy version identifier
SYSEXT_NAME="pypy" # Name for the Sysext
# --- End Configuration ---

PYPY_TARBALL_NAME="pypy${PYPY_VERSION_ID}-linux64.tar.bz2"
PYPY_DOWNLOAD_URL="https://downloads.python.org/pypy/${PYPY_TARBALL_NAME}"
PYPY_EXTRACTED_DIR="pypy${PYPY_VERSION_ID}-linux64"
BUILD_DIR=$(pwd)/build_sysext # Use a subdirectory in the workspace
ROOTFS_DIR="${BUILD_DIR}/rootfs"
SYSEXT_FILENAME="${SYSEXT_NAME}-sysext.raw"
SYSEXT_FILEPATH="${BUILD_DIR}/${SYSEXT_FILENAME}"
SHA256_FILEPATH="${SYSEXT_FILEPATH}.sha256"

echo "--- Starting PyPy Sysext Build ---"
echo "PyPy Version: ${PYPY_VERSION_ID}"
echo "Output Name: ${SYSEXT_FILENAME}"

# Clean and Create Build Directories
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"
mkdir -p "${ROOTFS_DIR}/opt/bin"

# Download PyPy
echo "Downloading ${PYPY_TARBALL_NAME}..."
curl -L "${PYPY_DOWNLOAD_URL}" -o "${BUILD_DIR}/${PYPY_TARBALL_NAME}"

# Extract PyPy binary to rootfs/opt/bin/python
echo "Extracting pypy3 binary..."
tar -xjf "${BUILD_DIR}/${PYPY_TARBALL_NAME}" \
    --strip-components=2 \
    -C "${ROOTFS_DIR}/opt/bin/" \
    "${PYPY_EXTRACTED_DIR}/bin/pypy3" \
    --transform='s/pypy3/python/'

echo "Extracted binary:"
ls -l "${ROOTFS_DIR}/opt/bin/python"

# Create SquashFS Image (Run mksquashfs with sudo as it's often needed)
echo "Creating SquashFS image: ${SYSEXT_FILENAME}..."
sudo mksquashfs "${ROOTFS_DIR}" "${SYSEXT_FILEPATH}" -noappend -comp xz -all-root

echo "Sysext image created: ${SYSEXT_FILEPATH}"
ls -lh "${SYSEXT_FILEPATH}"

# Generate SHA256 Hash
echo "Generating SHA256 hash..."
sha256sum "${SYSEXT_FILEPATH}" | cut -d' ' -f1 > "${SHA256_FILEPATH}"
SYSEXT_SHA256=$(cat "${SHA256_FILEPATH}")

echo "SHA256 Hash: ${SYSEXT_SHA256}"
echo "${SYSEXT_SHA256}" > "${BUILD_DIR}/sysext.sha256" # Store hash for Actions output

echo "--- Build Complete ---"
echo "Artifacts available in ${BUILD_DIR}"