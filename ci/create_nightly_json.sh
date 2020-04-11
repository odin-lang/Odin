FILE_IDS=$(b2 ls --long odin-binaries nightly | cut -d ' ' -f 1)

while IFS= read -r line; do
    echo "... $line ..."
done <<< "$list"