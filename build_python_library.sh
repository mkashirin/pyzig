#!/bin/bash

if [ -z "${ZIG_INSTALLED+x}" ]; then
    echo "Assuming Zig is not installed. Building with Python module..."
    python -m ziglang build
    python -m build
elif [ "$ZIG_INSTALLED" -eq 1 ]; then
    echo "Assuming Zig is installed. Building with Zig..."
    zig build
    python -m build
else
    echo "The environment variable ZIG_INSTALLED must be either 1 or not set."
fi
