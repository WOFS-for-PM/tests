#!/usr/bin/env bash


# Find all files matching the pattern
output_file="performance-comparison-table"
temp_file="merged-content.tmp"

# Clear the temporary file
> "$temp_file"

# Loop through matching files and append their content (excluding the first line)
for file in performance-comparison-table-splitfs*; do
    if [[ -f "$file" ]]; then
        tail -n +2 "$file" >> "$temp_file"
    fi
done

# Append the merged content to the output file
cat "$temp_file" >> "$output_file"

# Clean up temporary file
rm -f "$temp_file"