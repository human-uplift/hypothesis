#!/bin/bash

# Don't use set -e since we want to handle errors gracefully
# and provide useful error messages

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

# Create a virtual environment if requested
USE_VENV=false
VENV_DIR=".venv"

# Ask the user if they want to create a virtual environment
if [ ! -d "$VENV_DIR" ] && [ "$1" != "--no-venv" ]; then
    if command -v "$PYTHON_CMD" -m venv &> /dev/null; then
        echo "Creating virtual environment in $VENV_DIR..."
        "$PYTHON_CMD" -m venv "$VENV_DIR" || {
            echo "Warning: Failed to create virtual environment. Continuing with system Python."
        }
        
        if [ -d "$VENV_DIR" ]; then
            USE_VENV=true
        fi
    else
        echo "Warning: Python venv module not available. Continuing with system Python."
    fi
fi

# Activate the virtual environment if it exists
if [ -d "$VENV_DIR" ] && [ "$1" != "--no-venv" ]; then
    echo "Activating virtual environment..."
    # shellcheck disable=SC1090
    source "$VENV_DIR/bin/activate" || {
        echo "Warning: Failed to activate virtual environment. Continuing with system Python."
        USE_VENV=false
    }
    
    if [ "$USE_VENV" = true ]; then
        PIP_CMD="pip"
    else
        PIP_CMD="$PYTHON_CMD -m pip"
    fi
else
    PIP_CMD="$PYTHON_CMD -m pip"
fi

# Ensure pip is available
if ! command -v $PIP_CMD &> /dev/null; then
    echo "Error: pip not available. Please install pip and try again."
    exit 1
fi

# Upgrade pip if using venv
if [ "$USE_VENV" = true ]; then
    echo "Upgrading pip..."
    $PIP_CMD install --upgrade pip || echo "Warning: Failed to upgrade pip. Continuing..."
fi

# Install required dependencies for development
echo "Installing development dependencies..."
$PIP_CMD install --ignore-installed -r requirements/test.txt || echo "Warning: Some test dependencies may not have installed correctly, continuing..."
$PIP_CMD install --ignore-installed -r requirements/coverage.txt || echo "Warning: Some coverage dependencies may not have installed correctly, continuing..."

# Only install tools.txt if explicitly needed - it's very large and might cause issues
if [ "$2" = "--with-tools" ]; then
    echo "Installing tooling dependencies (this may take a while)..."
    $PIP_CMD install --ignore-installed -r requirements/tools.txt || echo "Warning: Some tools may not have installed correctly, continuing..."
fi

# Install the Python package in development mode
echo "Installing hypothesis-python in development mode..."
cd hypothesis-python || {
    echo "Error: Could not find hypothesis-python directory."
    exit 1
}

$PIP_CMD install -e . || {
    echo "Warning: Failed to install hypothesis-python in development mode."
}

cd .. || {
    echo "Error: Failed to return to root directory."
    exit 1
}

# Setup is complete
echo "Hypothesis development environment setup complete!"
if [ "$USE_VENV" = true ]; then
    echo "To activate the virtual environment, run: source $VENV_DIR/bin/activate"
fi

echo "For specific test runs, see the GitHub Actions workflow files for examples."
