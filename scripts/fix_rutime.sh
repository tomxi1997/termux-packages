#!/bin/bash

target_dir="$1"

if [[ -z "$target_dir" || ! -d "$target_dir" ]]; then
  echo "Error: Target directory '$target_dir' not provided or not found."
  echo "Usage: $0 <directory> <path_prefix>"
  exit 1
fi

replace_goos() {
    local file="$1"
    goos_usage_count=0
    remaining_runtime_usage=0
    should_remove_import=false

    goos_usage_count=$(grep -v '^\s*//' "$file" | grep -oP '\bruntime\.GOOS' | wc -l)

    if [[ "$goos_usage_count" -eq "0"  ]]; then
        return
    fi

    sed -i 's/runtime\.GOOS/"linux"/g' "$file"
   
    remaining_runtime_usage=$(grep -v '[\w.]runtime' $file | grep -v '^\s*//'  | grep -oP '\bruntime\.\w+'  | wc -l)

    if [[ "$remaining_runtime_usage" -eq "0"  ]]; then
      sed -i  's/"runtime"/_"runtime"/1' "$file"
    fi
}

find "$target_dir" -type f -name '*.go' -not -name '*_test.go' -print0 | while IFS= read -r -d $'\0' file; do
    replace_goos "$file"
done

exit 0