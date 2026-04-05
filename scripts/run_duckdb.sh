#!/usr/bin/env bash
# Run DuckDB inside an OrbStack container with --network=none
# Simulates a confidential database that cannot exfiltrate data
#
# Usage: ./scripts/run_duckdb.sh <sql_file> <output_dir>

set -euo pipefail

SQL_FILE="${1:?Usage: run_duckdb.sh <sql_file> <output_dir>}"
OUTPUT_DIR="${2:?Usage: run_duckdb.sh <sql_file> <output_dir>}"

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

mkdir -p "$OUTPUT_DIR"

docker run --rm \
  --network=none \
  --memory=2g \
  -v "$PROJECT_DIR/data:/data:ro" \
  -v "$PROJECT_DIR/scripts:/scripts:ro" \
  -v "$OUTPUT_DIR:/output" \
  duckdb/duckdb:latest \
  duckdb -cmd ".read /scripts/$SQL_FILE" -csv -noheader \
  2>&1
