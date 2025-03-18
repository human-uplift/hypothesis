#!/bin/bash

set -e

# Activate the virtual environment if it exists
VENV_DIR=".venv"
if [ -d "$VENV_DIR" ]; then
    source "$VENV_DIR/bin/activate"
fi

# Check if required tools are installed
if ! command -v ruff &> /dev/null; then
    echo "ruff not found. Please run setup.sh first."
    exit 1
fi

if ! command -v pyright &> /dev/null; then
    echo "pyright not found. Please run setup.sh first."
    exit 1
fi

# Run formatters
echo "Running formatters..."
ruff format hypothesis-python/src hypothesis-python/tests

# Run linters with fix flag
echo "Running linters..."
ruff check --fix hypothesis-python/src hypothesis-python/tests

# Run type checking on the Python package
echo "Running type checking..."
cd hypothesis-python
pyright
cd ..

echo "Precommit checks completed successfully!"
