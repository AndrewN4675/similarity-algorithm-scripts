#!/usr/bin/bash

SCRIPT_DIR="$(dirname "$0")"
SA_CONFIG_FILE="$SCRIPT_DIR/sa.config"

if [ $# -lt 3 ]; then
	echo "Usage: $0 PROJECT INPUT_DIR RESULTS_DIR"
	echo "   PROJECT      project name to analyze"
	echo "   INPUTS_DIR   path to directory containing extracted jar directories"
	echo "   RESULTS_DIR  path to directory containing results XML files"
	exit -1
fi

PROJECT=$1
INPUT_DIR=$2
RESULTS_DIR=$3

if [ ! -f "$SA_CONFIG_FILE" ]; then
	echo "No java configuration file found at '$SA_CONFIG_FILE'!"
	exit -2
fi

source "$SA_CONFIG_FILE"

if [ -z "$JAVA_BINARY" ]; then
	echo "JAVA_BINARY not set. Incorrect '$SA_CONFIG_FILE'."
	exit -2
fi

if [ ! -f "$JAVA_BINARY" ]; then
	echo "'$JAVA_BINARY' not found. Check your '$SA_CONFIG_FILE'."
	exit -2
fi

if [ -z "$SA_JAR" ]; then
	echo "SA_JAR not set. Incorrect '$SA_CONFIG_FILE'."
	exit -2
fi

if [ ! -f "$SA_JAR" ]; then
	echo "'$SA_JAR' not found. Check your '$SA_CONFIG_FILE'."
	exit -2
fi

PROJECT_DIR="$(realpath "$INPUT_DIR/$PROJECT")"
RESULTS_FILE="$(realpath "$RESULTS_DIR/$PROJECT.xml")"

TIMEOUT_FILE="$(realpath "$RESULTS_DIR/timeout")"
FAILURE_FILE="$(realpath "$RESULTS_DIR/failure")"
SUCCESS_FILE="$(realpath "$RESULTS_DIR/success")"

if [ ! -d "$PROJECT_DIR" ]; then
	echo "No project directory at '$PROJECT_DIR'"
	exit -3
fi

echo "Running similarity algorithm on project $PROJECT"
if [ -z "$SA_TIMEOUT" ]; then
	"$JAVA_BINARY" ${JAVA_ARGS:-} -jar "$SA_JAR" -target "$PROJECT_DIR" -output "$RESULTS_FILE"
	RETURN_CODE=$?
else
	timeout --signal "${SA_TIMEOUT_SIG:-TERM}" "$SA_TIMEOUT" "$JAVA_BINARY" ${JAVA_ARGS:-} -jar "$SA_JAR" -target "$PROJECT_DIR" -output "$RESULTS_FILE"
	RETURN_CODE=$?
fi

echo "RETURN CODE: $RETURN_CODE"

if [ $RETURN_CODE -eq 124 ] || [ $RETURN_CODE -eq 137 ]; then
	echo "Similarity algorithm on project $PROJECT timed out"
	echo "$PROJECT" >> "$TIMEOUT_FILE"
elif [ $RETURN_CODE -ne 0 ]; then
	echo "Similarity algorithm on project $PROJECT failed"
	echo "$PROJECT" >> "$FAILURE_FILE"
else
	echo "$PROJECT" >> "$SUCCESS_FILE"
fi

