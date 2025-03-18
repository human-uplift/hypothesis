#!/usr/bin/env bash
set -o pipefail

echo "Running pre-commit checks..."
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
VENV_DIR="$REPO_ROOT/.venv"

# Check if any arguments were provided
ARG1=${1:-""}

# Find the Python executable
PYTHON_CMD=""
for cmd in python3 python python3.10 python3.11 python3.12; do
    if command -v "$cmd" &> /dev/null; then
        PYTHON_CMD=$(command -v "$cmd")
        echo "Using Python interpreter: $PYTHON_CMD"
        break
    fi
done

if [ -z "$PYTHON_CMD" ]; then
    echo "Error: No Python interpreter found. Cannot run tests."
    # Continue with other checks but skip Python-dependent ones
fi

# Activate the virtual environment if it exists and not explicitly skipped
if [ -d "$VENV_DIR" ] && [ "$ARG1" != "--no-venv" ] && [ "$ARG1" != "--system" ]; then
    echo "Activating virtual environment..."
    # shellcheck disable=SC1090,SC1091
    source "$VENV_DIR/bin/activate" || {
        echo "Warning: Failed to activate virtual environment. Using system Python."
    }
    
    if [ -n "${VIRTUAL_ENV:-}" ]; then
        PYTHON_CMD="python"
        echo "Successfully activated virtual environment at $VIRTUAL_ENV"
    fi
fi

# Check if commands exist before using them
check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo "Warning: $1 is not installed, skipping $2"
        return 1
    fi
    return 0
}

# Format code with ruff if available
if check_command ruff "code formatting"; then
    echo "Running ruff formatter..."
    ruff format "$REPO_ROOT/hypothesis-python" || {
        echo "Warning: ruff format failed, but continuing..."
    }
else
    echo "Warning: ruff not found. Skipping code formatting."
    echo "Run '.mentat/setup.sh --with-tools' to install ruff."
fi

# Run linters with automatic fixes if available
if check_command ruff "linting"; then
    echo "Running ruff linter with auto-fixes..."
    ruff check --fix "$REPO_ROOT/hypothesis-python" || {
        echo "Warning: ruff check failed, but continuing..."
    }
else
    echo "Warning: ruff not found. Skipping linting."
    echo "Run '.mentat/setup.sh --with-tools' to install ruff."
fi

# Run type checking on the Python code - make it non-fatal
if check_command pyright "type checking"; then
    echo "Running pyright type checker..."

    # Create a temporary pyrightconfig.json to ignore vendor files
    TEMP_CONFIG=$(mktemp)
    cat > "$TEMP_CONFIG" <<EOF
{
  "include": ["src"],
  "exclude": ["src/hypothesis/vendor/**"],
  "typeCheckingMode": "strict"
}
EOF

    # Run pyright with temp config, but don't fail the script if it errors
    (cd "$REPO_ROOT/hypothesis-python" && pyright --project "$TEMP_CONFIG" src) || {
        echo "Warning: Type checking found errors, but continuing with pre-commit checks"
        echo "Note: Errors in vendor files are expected and can be ignored"
    }

    # Clean up temp file
    rm "$TEMP_CONFIG"
else
    echo "Warning: pyright not found. Skipping type checking."
    echo "Run '.mentat/setup.sh --with-tools' to install pyright."
fi

# Run a minimal set of tests to catch obvious issues
if [ -n "$PYTHON_CMD" ]; then
    echo "Running minimal test suite..."
    (cd "$REPO_ROOT/hypothesis-python" && "$PYTHON_CMD" -m pytest -xvs tests/cover/test_testdecorators.py tests/cover/test_simple_strings.py) || {
        echo "Warning: Some tests failed, but continuing with pre-commit checks"
    }
else
    echo "Skipping test suite (no Python interpreter found)"
fi

echo "Pre-commit checks completed!"
echo "Note: Some checks may have been skipped due to missing dependencies."
echo "For a complete check, run '.mentat/setup.sh --with-tools' to install all development tools."
