#!/bin/bash

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
