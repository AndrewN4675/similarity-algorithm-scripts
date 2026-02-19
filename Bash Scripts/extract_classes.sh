#!/usr/bin/bash

if [ $# -lt 2 ]; then
    echo 'USAGE: extract_classes.sh INPUT_JAR_DIR OUTPUT_CLASS_DIR'
    exit -1
fi

input_dir=$1
output_dir=$2

# Use glob pattern instead of ls to handle spaces properly
for project_path in "$input_dir"/*; do
    [ -d "$project_path" ] || continue
    project=$(basename "$project_path")
    echo "PROJ: $project"

    for jar_path in "$input_dir/$project"/*.jar; do
        [ -f "$jar_path" ] || continue
        jarfile=$(basename "$jar_path")
        mkdir -p "$output_dir/$project"
        unzip "$jar_path" -o -d "$output_dir/$project"
    done
done