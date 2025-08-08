#!/bin/bash
set -e # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_status() {
  echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
  echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

print_note() {
  echo -e "${BLUE}[NOTE]${NC} $1"
}

git submodule update --init --recursive

ARCH_DEPS=(
  "arm-none-eabi-gcc"
  "arm-none-eabi-newlib"
  "cmake"
  "base-devel"
  "curl"
  "python3"
  "libmpc"
  "mpfr"
  "gmp"
  "texinfo"
  "gperf"
  "patchutils"
  "bc"
  "zlib"
  "expat"
  "libslirp"
  "git"
  "autoconf"
  "automake"
  "libtool"
  "pkg-config"
  "libusb"
)

print_status "Installing dependencies for Arch Linux..."

# Update package database
sudo pacman -Sy

# Install dependencies
sudo pacman -S --needed "${ARCH_DEPS[@]}"

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USERNAME=$(whoami)

# Define paths
TOOLCHAIN_DIR="$SCRIPT_DIR/tools/riscv-gnu-toolchain"
BIN_DIR="$SCRIPT_DIR/bin"
PICOTOOL_DIR="$SCRIPT_DIR/tools/pico/picotool"

print_status "Starting RISC-V toolchain build process..."
print_status "Script directory: $SCRIPT_DIR"
print_status "Toolchain source: $TOOLCHAIN_DIR"
print_status "Install prefix: $PREFIX_DIR"

# Check if toolchain directory exists
if [ ! -d "$TOOLCHAIN_DIR" ]; then
  print_error "Toolchain directory not found: $TOOLCHAIN_DIR"
  print_error "Please ensure the riscv-gnu-toolchain is located at tools/riscv-gnu-toolchain"
  exit 1
fi

# Create bin directory if it doesn't exist
print_status "Creating binary directory..."
mkdir -p "$BIN_DIR"

# Change to toolchain directory
print_status "Entering toolchain directory..."
cd "$TOOLCHAIN_DIR"

# Check if configure script exists
if [ ! -f "./configure" ]; then
  print_error "Configure script not found in $TOOLCHAIN_DIR"
  print_error "You may need to run 'git submodule update --init --recursive' first"
  exit 1
fi

# Configure the build
print_status "Configuring build with custom parameters..."
./configure \
  --prefix="$BIN_DIR" \
  --with-arch=rv32ima_zicsr_zifencei_zba_zbb_zbkb_zbs \
  --with-abi=ilp32 \
  --with-multilib-generator="rv32ima_zicsr_zifencei_zba_zbb_zbs_zbkb-ilp32--"

if [ $? -ne 0 ]; then
  print_error "Configuration failed!"
  exit 1
fi

print_status "Configuration completed successfully"

# Build the toolchain
print_status "Starting build process (using $(nproc) parallel jobs)..."

make -j $(nproc)

if [ $? -ne 0 ]; then
  print_error "Build failed!"
  exit 1
fi

print_status "Build completed successfully!"

# Change to picotool directory
cd "$PICOTOOL_DIR"

# Create build directory
print_status "Creating build directory..."
rm -rf build # Clean previous build
mkdir build
cd build

# Set environment variable
export PICO_SDK_PATH="$PICO_SDK_PATH"
print_status "Set PICO_SDK_PATH=$PICO_SDK_PATH"

# Configure with cmake
print_status "Configuring build with cmake..."
cmake -DCMAKE_INSTALL_PREFIX="$BIN_DIR" -DPICOTOOL_FLAT_INSTALL=1 ..

if [ $? -ne 0 ]; then
  print_error "CMake configuration failed!"
  exit 1
fi

# Build picotool
print_status "Building picotool..."
make -j $(nproc)

if [ $? -ne 0 ]; then
  print_error "Build failed!"
  exit 1
fi

# Install picotool
print_status "Installing picotool..."
make install

# Setup udev rules
print_status "Setting up udev rules..."
UDEV_RULES_SRC="$PICOTOOL_DIR/udev/99-picotool.rules"
UDEV_RULES_DEST="/etc/udev/rules.d/99-picotool.rules"

if [ -f "$UDEV_RULES_SRC" ]; then
  print_warning "Setting up udev rules requires sudo access"
  sudo cp "$UDEV_RULES_SRC" "$UDEV_RULES_DEST"
  sudo udevadm control --reload-rules && sudo udevadm trigger
  print_status "Udev rules installed and reloaded"
else
  print_warning "Udev rules file not found at $UDEV_RULES_SRC"
fi

# Setup plugdev group
print_status "Setting up plugdev group..."
if ! getent group plugdev >/dev/null 2>&1; then
  print_status "Creating plugdev group..."
  sudo groupadd plugdev
else
  print_status "plugdev group already exists"
fi

# Add user to plugdev group
if ! groups "$USERNAME" | grep -q plugdev; then
  print_status "Adding user $USERNAME to plugdev group..."
  sudo usermod -aG plugdev "$USERNAME"
  print_warning "You may need to log out and log back in for group changes to take effect"
else
  print_status "User $USERNAME is already in plugdev group"
fi

print_status "Picotool installation process completed!"
