#!/bin/bash

# Get the target directory from first argument or use current directory
TARGET_DIR="${1:-.}"
# Get output format from second argument or default to txt
OUTPUT_FORMAT="${2:-txt}"
# Remove leading dot if present in format
OUTPUT_FORMAT="${OUTPUT_FORMAT#.}"
IGNORE_FILE=".countignore"
DEBUG=${DEBUG:-0}

# Validate directory exists
if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: Directory '$TARGET_DIR' does not exist"
    exit 1
fi

# Convert to absolute path
TARGET_DIR=$(cd "$TARGET_DIR" && pwd)

# Output file name (in the current directory)
output_file="code_lines_report.$OUTPUT_FORMAT"

# Progress bar function
progress_bar() {
    local current=$1
    local total=$2
    local width=50
    local percentage=$((current * 100 / total))
    local filled=$((width * current / total))
    local empty=$((width - filled))
    local fill_char="="
    local empty_char=" "
    
    printf -v filled_bar "%${filled}s" ""
    printf -v empty_bar "%${empty}s" ""
    filled_bar=${filled_bar// /$fill_char}
    
    printf "\rProcessing files: [%s%s] %d%%" "$filled_bar" "$empty_bar" "$percentage"
    
    if [ "$current" -eq "$total" ]; then
        echo -e "\nDone processing files!"
    fi
}

# Function to get file extension
get_extension() {
    filename=$1
    extension="${filename##*.}"
    if [ "$extension" = "$filename" ]; then
        echo "no_extension"
    else
        echo "$extension"
    fi
}

# Function to check if a file should be ignored
should_ignore() {
    local file="$1"
    local relative_path="${file#$TARGET_DIR/}"
    
    [ "$DEBUG" = "1" ] && echo "Checking file: $relative_path" >&2
    
    # Always ignore hidden files and directories
    if [[ "$relative_path" =~ /\. || "$relative_path" =~ ^\. ]]; then
        [ "$DEBUG" = "1" ] && echo "Ignoring hidden file/directory: $relative_path" >&2
        return 0
    fi
    
    # If ignore file doesn't exist, only ignore hidden files
    if [ ! -f "$TARGET_DIR/$IGNORE_FILE" ]; then
        [ "$DEBUG" = "1" ] && echo "No $IGNORE_FILE found" >&2
        return 1
    fi
    
    while IFS= read -r pattern || [ -n "$pattern" ]; do
        # Skip empty lines and comments
        [[ -z "$pattern" || "$pattern" =~ ^# ]] && continue
        
        # Remove leading and trailing whitespace
        pattern=$(echo "$pattern" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        
        [ "$DEBUG" = "1" ] && echo "Testing pattern: $pattern" >&2
        
        # Handle directory/* patterns
        if [[ "$pattern" == *"/*" ]]; then
            local dir_pattern="${pattern%/*}"
            if [[ "$relative_path" == "$dir_pattern"* ]]; then
                [ "$DEBUG" = "1" ] && echo "Matched directory pattern: $dir_pattern" >&2
                return 0
            fi
        # Handle exact matches and other patterns
        elif [[ "$relative_path" == *"$pattern"* ]]; then
            [ "$DEBUG" = "1" ] && echo "Matched pattern: $pattern" >&2
            return 0
        fi
    done < "$TARGET_DIR/$IGNORE_FILE"
    
    return 1
}

# Create temporary files
temp_file=$(mktemp)
dir_summary=$(mktemp)
files_list=$(mktemp)

# Initialize output file based on format
if [ "$OUTPUT_FORMAT" = "csv" ]; then
    echo "Directory,File,Lines" > "$output_file"
else
    {
        echo "CODE LINES COUNT REPORT"
        echo "Date: $(date)"
        echo "Target Directory: $TARGET_DIR"
        [ -f "$TARGET_DIR/$IGNORE_FILE" ] && echo "Using ignore patterns from: $IGNORE_FILE"
        echo "----------------------------------------"
        echo -e "\nFILE DETAILS BY DIRECTORY:"
        echo "----------------------------------------"
    } > "$output_file"
fi

echo "Starting file analysis..."
echo "Analyzing directory: $TARGET_DIR"

# Create list of files that aren't ignored
echo "Creating list of files to process..." >&2
while IFS= read -r -d '' file; do
    if ! should_ignore "$file"; then
        echo "$file" >> "$files_list"
    fi
done < <(find "$TARGET_DIR" -type f -print0)

# Count total files for progress bar
total_files=$(wc -l < "$files_list")
current_file=0

# Process each non-ignored file
while IFS= read -r file; do
    # Update progress
    ((current_file++))
    progress_bar "$current_file" "$total_files"
    
    # Get directory path and filename
    dir_path=$(dirname "$file")
    filename=$(basename "$file")
    
    # Count non-empty lines
    lines=$(grep -c . "$file" 2>/dev/null || echo "0")
    
    # Save results
    echo "$dir_path:$filename:$lines" >> "$temp_file"
    ext=$(get_extension "$filename")
    echo "$ext:$lines" >> "$dir_summary"
done < "$files_list"

echo -e "\nGenerating report..."

# Process results based on format
if [ "$OUTPUT_FORMAT" = "csv" ]; then
    # CSV format
    sort "$temp_file" | while IFS=':' read -r dir filename lines; do
        echo "$dir,$filename,$lines" >> "$output_file"
    done
else
    # TXT format
    sort "$temp_file" | while IFS=':' read -r dir filename lines; do
        if [ "$current_dir" != "$dir" ]; then
            echo -e "\n$dir/" >> "$output_file"
            current_dir="$dir"
        fi
        printf "%-30s %8d lines\n" "$filename" "$lines" >> "$output_file"
    done
fi

# Add summary section
if [ "$OUTPUT_FORMAT" = "csv" ]; then
    {
        echo -e "\nEXTENSION SUMMARY"
        echo "Extension,Total Lines,File Count"
    } >> "$output_file"
    
    awk -F':' '
        {ext[$1] += $2; count[$1]++}
        END {
            for (e in ext) {
                printf "%s,%d,%d\n", e, ext[e], count[e]
            }
        }
    ' "$dir_summary" | sort -t',' -k2,2nr >> "$output_file"
else
    {
        echo -e "\nSUMMARY BY FILE TYPE:"
        echo "----------------------------------------"
    } >> "$output_file"
    
    awk -F':' '
        {ext[$1] += $2; count[$1]++}
        END {
            for (e in ext) {
                printf "%-20s %8d lines in %4d files\n", e, ext[e], count[e]
            }
        }
    ' "$dir_summary" | sort -t':' -k2,2nr >> "$output_file"
fi

# Add final totals
total_lines=$(awk -F':' '{sum += $3} END {print sum}' "$temp_file")
total_files=$(wc -l < "$temp_file")

if [ "$OUTPUT_FORMAT" = "csv" ]; then
    {
        echo -e "\nGENERAL SUMMARY"
        echo "Metric,Value"
        echo "Total Lines,$total_lines"
        echo "Total Files,$total_files"
    } >> "$output_file"
else
    {
        echo -e "\nGENERAL SUMMARY:"
        echo "----------------------------------------"
        echo "Total lines: $total_lines"
        echo "Total files: $total_files"
    } >> "$output_file"
fi

# Clean up temporary files
rm -f "$temp_file" "$dir_summary" "$files_list"

echo "Report generated in $output_file"
