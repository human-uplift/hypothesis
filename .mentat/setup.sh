#!/bin/bash

set -e

# Create a virtual environment if it doesn't exist
VENV_DIR=".venv"
if [ ! -d "$VENV_DIR" ]; then
    echo "Creating virtual environment in $VENV_DIR..."
    python -m venv $VENV_DIR
fi

# Activate the virtual environment
source "$VENV_DIR/bin/activate"

# Upgrade pip
echo "Upgrading pip..."
pip install --upgrade pip

# Install required dependencies for development
echo "Installing development dependencies..."
pip install --ignore-installed -r requirements/tools.txt || echo "Some tools may not have installed correctly, continuing..."
pip install --ignore-installed -r requirements/test.txt || echo "Some test dependencies may not have installed correctly, continuing..."
pip install --ignore-installed -r requirements/coverage.txt || echo "Some coverage dependencies may not have installed correctly, continuing..."

# Install the Python package in development mode
echo "Installing hypothesis-python in development mode..."
cd hypothesis-python
pip install -e .[all]
cd ..

# Setup is complete
echo "Hypothesis development environment setup complete!"
echo "To activate the virtual environment, run: source $VENV_DIR/bin/activate"
