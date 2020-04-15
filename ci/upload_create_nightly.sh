#!/bin/bash

bucket=$1
platform=$2
artifact=$3

now=$(date +'%Y-%m-%d')
filename="odin-$platform-nightly+$now.zip"

echo "Creating archive $filename from $artifact and uploading to $bucket"

7z a -bd "output/$filename" -r "$artifact"
b2 upload-file --noProgress "$bucket" "output/$filename" "nightly/$filename"