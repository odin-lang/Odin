#!/bin/bash

set -e

bucket=$1
platform=$2
artifact=$3

now=$(date +'%Y-%m-%d')
filename="odin-$platform-nightly+$now.zip"

echo "Creating archive $filename from $artifact and uploading to $bucket"

# If this is already zipped up (done before artifact upload to keep permissions in tact), just move it.
if [ "${artifact: -4}" == ".zip" ]
then
	echo "Artifact already a zip"
	mkdir -p "output"
	mv "$artifact" "output/$filename"
else
	echo "Artifact needs to be zipped"
	7z a -bd "output/$filename" -r "$artifact"
fi

b2 upload-file --noProgress "$bucket" "output/$filename" "nightly/$filename"
