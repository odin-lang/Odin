#!/bin/bash

bucket=$1
platform=$2
artifact=$2

now=$(date +'%Y-%m-%d')
filename="odin-$platform-nightly+$now.zip"

7z a "output/$filename" -r "$artifact"
b2 upload-file "$bucket" "$filename" "$filename"