#!/usr/bin/bash

SCRIPT_DIR="$(dirname "$0")"
RUN_SA="$SCRIPT_DIR/run_similarity_algorithm.sh"

if [ $# -lt 2 ]; then
	echo "Usage: $0 INPUT_DIR RESULTS_DIR"
	echo "   INPUT_DIR    path to directory containing extracted jar directories"
	echo "   RESULTS_DIR  path to directory containing result XML files"
	exit -1
fi

INPUT_DIR=$1
RESULTS_DIR=$2

if [ ! -d "$INPUT_DIR" ]; then
	echo "Input directory '$INPUT_DIR' does not exist"
	exit -2
fi

mkdir -p "$RESULTS_DIR"

PROJECTS="$(ls --escape "$INPUT_DIR")"

echo "Projects: [ ${PROJECTS[@]} ]"

for PROJECT in ${PROJECTS[@]}; do
	$RUN_SA "$PROJECT" "$INPUT_DIR" "$RESULTS_DIR"
done
