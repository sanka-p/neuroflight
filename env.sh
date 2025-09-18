#!/bin/bash

export SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

export PATH="$SCRIPT_DIR/tools/riscv-gnu-toolchain/build/bin:$PATH"
export PATH="$SCRIPT_DIR/tools/pico/picotool/bin/picotool:$PATH"
export picotool_DIR="$SCRIPT_DIR/tools/pico/picotool/bin"
export PICO_SDK_PATH="$SCRIPT_DIR/tools/pico/pico-sdk"
export PICO_BOARD="pico2"
export PICO_PLATFORM="rp2350-riscv"
