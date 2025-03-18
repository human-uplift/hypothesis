#!/bin/bash

# Don't use set -e since we want to handle errors gracefully

# Find available Python command
if command -v python3 &> /dev/null; then
    PYTHON_CMD="python3"
elif command -v python &> /dev/null; then
    PYTHON_CMD="python"
else
    echo "Error: Could not find Python. Please install Python 3.9+ and try again."
    exit 1
fi

echo "Using Python command: $PYTHON_CMD"

# Activate the virtual environment if it exists
VENV_DIR=".venv"
if [ -d "$VENV_DIR" ] && [ "$1" != "--no-venv" ]; then
    echo "Activating virtual environment..."
    # shellcheck disable=SC1090
    source "$VENV_DIR/bin/activate" || {
        echo "Warning: Failed to activate virtual environment. Using system Python."
    }
fi

# Run basic checks with Python's built-in tools
echo "Running flake8 equivalent check..."
"$PYTHON_CMD" -m pyflakes hypothesis-python/src hypothesis-python/tests || {
    echo "Warning: pyflakes check failed, but continuing..."
}

# Run formatters if ruff is available
if command -v ruff &> /dev/null; then
    echo "Running formatters..."
    ruff format hypothesis-python/src hypothesis-python/tests || {
        echo "Warning: ruff format failed, but continuing..."
    }

    echo "Running linters..."
    ruff check --fix hypothesis-python/src hypothesis-python/tests || {
        echo "Warning: ruff check failed, but continuing..."
    }
else
    echo "Warning: ruff not found. Skipping code formatting and linting."
    echo "Run 'setup.sh --with-tools' to install ruff and other development tools."
fi

# Run type checking if pyright is available
if command -v pyright &> /dev/null; then
    echo "Running type checking..."
    cd hypothesis-python || {
        echo "Error: Could not find hypothesis-python directory."
        exit 1
    }
    
    pyright || {
        echo "Warning: pyright check failed, but continuing..."
    }
    
    cd .. || {
        echo "Error: Failed to return to root directory."
        exit 1
    }
else
    echo "Warning: pyright not found. Skipping type checking."
    echo "Run 'setup.sh --with-tools' to install pyright and other development tools."
fi

# Run basic tests to ensure code is working
echo "Running basic tests..."
"$PYTHON_CMD" -m pytest hypothesis-python/tests/cover/test_simple_strings.py -v || {
    echo "Warning: Basic tests failed. You might want to fix these issues before committing."
}

echo "Precommit checks completed!"
echo "Note: Some checks may have been skipped due to missing dependencies."
echo "For a complete check, run 'setup.sh --with-tools' to install all development tools."
