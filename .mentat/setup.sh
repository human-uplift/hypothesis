#!/bin/bash

# Install required dependencies for development
echo "Installing development dependencies..."
pip install -r requirements/tools.txt
pip install -r requirements/test.txt
pip install -r requirements/coverage.txt

# Install the Python package in development mode
echo "Installing hypothesis-python in development mode..."
cd hypothesis-python
pip install -e .[all]
cd ..

# Setup is complete
echo "Hypothesis development environment setup complete!"
