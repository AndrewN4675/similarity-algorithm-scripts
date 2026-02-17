#!/usr/bin/bash

if [ $# -lt 2 ]; then
	echo 'USAGE: extract_classes.sh INPUT_JAR_DIR OUTPUT_CLASS_DIR'
	exit -1
fi

input_dir=$1
output_dir=$2

projects=($(ls "$input_dir"))

for project in ${projects[@]}; do
	echo "PROJ: $project"

	jars=($(ls "$input_dir/$project"))

	for jarfile in ${jars[@]}; do
		mkdir -p "$output_dir/$project"
		unzip "$input_dir/$project/$jarfile" -o -d "$output_dir/$project"
	done
done

echo ${projects[@]}

