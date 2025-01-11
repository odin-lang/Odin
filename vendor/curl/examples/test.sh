#!/bin/bash
set -e

cd "$(dirname "$0")"

for example in *.odin; do
  echo "Building and running $example..."
  odin run "$example" -file -vet -strict-style
done
