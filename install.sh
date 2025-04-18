#!/bin/bash

# This scripts is intended to be executed from virtual environment only!

if [ -z "${ZIG_INSTALLED+x}" ]; then
    echo "Assuming Zig is not installed. Building with Python module..."
    python -m ziglang build
    python -m hatch build
    python -m uv pip install .
elif [ "$ZIG_INSTALLED" -eq 1 ]; then
    echo "Assuming Zig is installed. Building with Zig..."
    zig build
    python -m hatch build
    python -m uv pip install .
else
    echo "The environment variable ZIG_INSTALLED must be either 1 or not set."
fi
