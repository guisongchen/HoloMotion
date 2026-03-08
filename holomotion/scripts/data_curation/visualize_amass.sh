#!/bin/bash
# Visualize AMASS NPZ files with automatic cleanup
# Usage: bash visualize_amass.sh /path/to/file.npz [--port PORT]

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
CONDA_ENV="holomotion_train"
PYTHON_SCRIPT="${PROJECT_ROOT}/holomotion/src/data_curation/smpl_npz_to_html.py"
TEMPLATE="${PROJECT_ROOT}/holomotion/src/data_curation/templates/index_wooden_static.html"
WOODEN_MODEL_DIR="${PROJECT_ROOT}/WoodenModel/dump_wooden"

# Parse arguments
NPZ_FILE=""
PORT="${2:-8765}"

show_usage() {
    echo "Usage: bash visualize_amass.sh /path/to/file.npz [PORT]"
    echo ""
    echo "Examples:"
    echo "  bash visualize_amass.sh data/amass/ACCAD/Male1General_c3d/General_A5_-_Pick_Up_Box_stageii.npz"
    echo "  bash visualize_amass.sh ~/my_motion.npz 8888"
    exit 1
}

# Check arguments
if [ $# -lt 1 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_usage
fi

NPZ_FILE="$1"
if [ $# -ge 2 ]; then
    PORT="$2"
fi

# Validate NPZ file exists
if [ ! -f "$NPZ_FILE" ]; then
    echo "Error: NPZ file not found: $NPZ_FILE"
    exit 1
fi

# Get absolute path
NPZ_FILE="$(cd "$(dirname "$NPZ_FILE")" && pwd)/$(basename "$NPZ_FILE")"

# Validate dependencies
if [ ! -d "$WOODEN_MODEL_DIR" ]; then
    echo "Error: WoodenModel not found at $WOODEN_MODEL_DIR"
    exit 1
fi

if [ ! -f "$PYTHON_SCRIPT" ]; then
    echo "Error: smpl_npz_to_html.py not found at $PYTHON_SCRIPT"
    exit 1
fi

# Setup conda
CONDA_BASE=$(conda info --base 2>/dev/null) || {
    echo "Error: conda not found. Please activate conda first."
    exit 1
}
source "$CONDA_BASE/etc/profile.d/conda.sh"

if ! conda activate "$CONDA_ENV" 2>/dev/null; then
    echo "Error: Failed to activate conda environment '$CONDA_ENV'"
    echo "Available environments:"
    conda env list
    exit 1
fi

# Create temp directory
WORK_DIR=$(mktemp -d)
OUTPUT_HTML="${WORK_DIR}/amass_vis.html"

cleanup() {
    echo ""
    echo "Cleaning up..."

    # Kill HTTP server if running
    if [ -n "$SERVER_PID" ] && kill -0 "$SERVER_PID" 2>/dev/null; then
        echo "  Stopping HTTP server (PID: $SERVER_PID)..."
        kill "$SERVER_PID" 2>/dev/null || true
        wait "$SERVER_PID" 2>/dev/null || true
    fi

    # Remove temp directory
    if [ -d "$WORK_DIR" ]; then
        echo "  Removing temp files..."
        rm -rf "$WORK_DIR"
    fi

    echo "Done."
}

# Register cleanup on exit
trap cleanup EXIT INT TERM

echo "======================================"
echo "AMASS Motion Visualization"
echo "======================================"
echo "File: $(basename "$NPZ_FILE")"
echo "Port: $PORT"
echo "Work dir: $WORK_DIR"
echo ""

# Step 1: Generate HTML
echo "[1/4] Generating visualization HTML..."
python "$PYTHON_SCRIPT" \
    --npz "$NPZ_FILE" \
    --template "$TEMPLATE" \
    --out "$OUTPUT_HTML" \
    --pose_joints 55

if [ ! -f "$OUTPUT_HTML" ]; then
    echo "Error: Failed to generate HTML"
    exit 1
fi

# Step 2: Copy model files
echo "[2/4] Copying model files..."
cp -r "$WOODEN_MODEL_DIR" "$WORK_DIR/"

# Check if port is in use and kill existing server
echo "[3/4] Checking port $PORT..."
EXISTING_PID=$(lsof -t -i :"$PORT" 2>/dev/null || true)
if [ -n "$EXISTING_PID" ]; then
    echo "        Port $PORT in use (PID: $EXISTING_PID), stopping old server..."
    kill "$EXISTING_PID" 2>/dev/null || true
    sleep 1
fi

# Try to find an available port if still in use
while lsof -i :"$PORT" > /dev/null 2>&1; do
    PORT=$((PORT + 1))
    if [ "$PORT" -gt 9000 ]; then
        echo "Error: No available ports found (tried up to 9000)"
        exit 1
    fi
done
echo "        Using port $PORT"

# Start HTTP server
echo "        Starting HTTP server..."
cd "$WORK_DIR"
python3 -m http.server "$PORT" > /dev/null 2>&1 &
SERVER_PID=$!

# Wait for server to start
sleep 2
if ! kill -0 "$SERVER_PID" 2>/dev/null; then
    echo "Error: Failed to start HTTP server"
    exit 1
fi

# Verify server is responding
if ! curl -s -o /dev/null -w "%{http_code}" "http://localhost:$PORT/amass_vis.html" | grep -q "200"; then
    echo "Error: HTTP server not responding"
    exit 1
fi

echo "        Server running at http://localhost:$PORT"

# Step 4: Open browser
echo "[4/4] Opening browser..."
URL="http://localhost:$PORT/amass_vis.html"

if command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$URL"
elif command -v google-chrome >/dev/null 2>&1; then
    google-chrome "$URL" &
elif command -v firefox >/dev/null 2>&1; then
    firefox "$URL" &
else
    echo "        Please open manually: $URL"
fi

echo ""
echo "======================================"
echo "Visualization ready!"
echo "URL: $URL"
echo ""
echo "Press Ctrl+C to stop server and cleanup"
echo "======================================"

# Keep script running until interrupted
wait "$SERVER_PID" 2>/dev/null || true
