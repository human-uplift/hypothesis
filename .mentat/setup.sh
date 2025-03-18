#!/usr/bin/env bash
set -o pipefail

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
VENV_DIR="$REPO_ROOT/.venv"
USE_VENV=false

# Check if any arguments were provided
ARG1=${1:-""}
ARG2=${2:-""}

echo "Installing Hypothesis development dependencies..."

# Find the appropriate pip command
PIP_CMD=""
for cmd in pip3 pip pip3.10 pip3.11 pip3.12; do
    if command -v "$cmd" &> /dev/null; then
        PIP_CMD="$cmd"
        echo "Using pip: $PIP_CMD"
        break
    fi
done

# If no pip found, try to find Python and use its pip module
if [ -z "$PIP_CMD" ]; then
    for cmd in python3 python python3.10 python3.11 python3.12; do
        if command -v "$cmd" &> /dev/null; then
            PYTHON_CMD=$(command -v "$cmd")
            echo "No pip found, using Python module: $PYTHON_CMD -m pip"
            PIP_CMD="$PYTHON_CMD -m pip"
            break
        fi
    done
fi

# If still no pip, exit with error
if [ -z "$PIP_CMD" ]; then
    echo "Error: No pip command found. Cannot install dependencies."
    exit 1
fi

# If using Python -m pip, extract the Python command
if [[ "$PIP_CMD" == *"-m pip" ]]; then
    PYTHON_CMD=${PIP_CMD%-m pip}
# Otherwise find the Python executable that corresponds to the pip we're using
elif [[ "$PIP_CMD" == pip3* ]]; then
    PYTHON_CMD="${PIP_CMD/pip/python}"
else
    PYTHON_CMD="python3"
    if ! command -v "$PYTHON_CMD" &> /dev/null; then
        PYTHON_CMD="python"
    fi
fi

echo "Using Python interpreter: $PYTHON_CMD"

# Create a virtual environment if requested
if [ "$ARG1" != "--no-venv" ] && [ "$ARG1" != "--system" ]; then
    if command -v "$PYTHON_CMD" -m venv &> /dev/null; then
        if [ ! -d "$VENV_DIR" ]; then
            echo "Creating virtual environment in $VENV_DIR..."
            "$PYTHON_CMD" -m venv "$VENV_DIR" || {
                echo "Warning: Failed to create virtual environment. Continuing with system Python."
            }
        fi
        
        if [ -d "$VENV_DIR" ]; then
            echo "Activating virtual environment..."
            # shellcheck disable=SC1090,SC1091
            source "$VENV_DIR/bin/activate" || {
                echo "Warning: Failed to activate virtual environment. Continuing with system Python."
            }
            
            if [ -n "${VIRTUAL_ENV:-}" ]; then
                USE_VENV=true
                PIP_CMD="pip"
                PYTHON_CMD="python"
                echo "Successfully activated virtual environment at $VIRTUAL_ENV"
                
                # Upgrade pip in virtual environment
                echo "Upgrading pip..."
                $PIP_CMD install --upgrade pip wheel setuptools
            fi
        fi
    else
        echo "Warning: Python venv module not available. Continuing with system Python."
    fi
fi

# Install known problematic packages individually
echo "Installing potentially problematic packages individually..."
$PIP_CMD install --ignore-installed wheel setuptools pip || echo "Warning: Failed to install basic packages, but continuing..."

# First install the test dependencies 
echo "Installing test dependencies..."
$PIP_CMD install --ignore-installed -r "$REPO_ROOT/requirements/test.txt" || echo "Warning: Some test dependencies may not have installed correctly, continuing..."

# Then install coverage dependencies with --no-deps to avoid conflicts
echo "Installing coverage dependencies..."
$PIP_CMD install --ignore-installed --no-deps -r "$REPO_ROOT/requirements/coverage.txt" || echo "Warning: Some coverage dependencies may not have installed correctly, continuing..."

# Only install tools.txt if explicitly requested
if [ "$ARG1" = "--with-tools" ] || [ "$ARG2" = "--with-tools" ]; then
    echo "Installing tooling dependencies (this may take a while)..."
    $PIP_CMD install --ignore-installed --no-deps -r "$REPO_ROOT/requirements/tools.txt" || echo "Warning: Some tools may not have installed correctly, continuing..."
fi

# Install the Python package in development mode
echo "Installing hypothesis-python in development mode..."
$PIP_CMD install --ignore-installed -e "$REPO_ROOT/hypothesis-python/[all]" || {
    echo "Warning: Failed to install hypothesis-python in development mode."
}

# Verify the installation
echo "Verifying installation..."
$PYTHON_CMD -c "import hypothesis; print(f'Successfully installed hypothesis version {hypothesis.__version__}')" || {
    echo "Warning: Could not verify hypothesis installation. It might not be working correctly."
}

# Setup is complete
echo "Hypothesis development environment setup complete!"
if [ "$USE_VENV" = true ]; then
    echo "To activate the virtual environment, run: source $VENV_DIR/bin/activate"
fi

echo "For specific test runs, see the GitHub Actions workflow files for examples."
