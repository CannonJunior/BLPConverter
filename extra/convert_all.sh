#!/bin/bash

# BLP to PNG Converter Script
# Recursively converts all .blp files in a directory to .png format

# Default values
CONVERTER="./build/bin/BLPConverter"
REMOVE_BLP=false
VERBOSE=false
ROOT_DIR=""

# Function to display usage
usage() {
    echo "Usage: $0 [OPTIONS] <directory>"
    echo ""
    echo "Convert all BLP files in <directory> and subdirectories to PNG format"
    echo ""
    echo "Options:"
    echo "  --converter PATH    Path to BLPConverter executable (default: ./build/bin/BLPConverter)"
    echo "  --remove           Remove BLP files after successful conversion"
    echo "  --verbose          Show detailed output"
    echo "  --help             Show this help message"
    echo ""
    echo "Example:"
    echo "  $0 /path/to/blp/files"
    echo "  $0 --converter ../build/BLPConverter --verbose /path/to/blp/files"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --converter)
            CONVERTER="$2"
            shift 2
            ;;
        --remove)
            REMOVE_BLP=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --help)
            usage
            exit 0
            ;;
        -*)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
        *)
            if [[ -z "$ROOT_DIR" ]]; then
                ROOT_DIR="$1"
            else
                echo "Error: Multiple directories specified"
                usage
                exit 1
            fi
            shift
            ;;
    esac
done

# Check if directory was provided
if [[ -z "$ROOT_DIR" ]]; then
    echo "Error: No directory specified"
    usage
    exit 1
fi

# Check if directory exists
if [[ ! -d "$ROOT_DIR" ]]; then
    echo "Error: Directory '$ROOT_DIR' does not exist"
    exit 1
fi

# Check if converter exists and is executable
if [[ ! -x "$CONVERTER" ]]; then
    echo "Error: BLPConverter not found or not executable at '$CONVERTER'"
    echo "Make sure to build the project first with: mkdir build && cd build && cmake .. && make"
    exit 1
fi

# Initialize counters
total_converted=0
total_failed=0
failed_files=()

echo "Starting BLP to PNG conversion..."
echo "Root directory: $ROOT_DIR"
echo "Converter: $CONVERTER"
echo "Remove BLP files: $REMOVE_BLP"
echo "Verbose output: $VERBOSE"
echo ""

# Find all BLP files first
echo "Scanning for BLP files..."
readarray -t blp_files < <(find "$ROOT_DIR" -type f -iname "*.blp")

if [[ ${#blp_files[@]} -eq 0 ]]; then
    echo "No BLP files found in $ROOT_DIR"
    exit 0
fi

echo "Found ${#blp_files[@]} BLP files to convert"
echo ""

# Process each file
for blp_file in "${blp_files[@]}"; do
    # Get relative path for display
    rel_path="${blp_file#$ROOT_DIR/}"
    
    if [[ "$VERBOSE" == true ]]; then
        echo -n "Processing: $rel_path ... "
    fi
    
    # Convert the file (output to same directory as input)
    blp_dir="$(dirname "$blp_file")"
    if "$CONVERTER" -o "$blp_dir" "$blp_file" >/dev/null 2>&1; then
        ((total_converted++))
        
        if [[ "$VERBOSE" == true ]]; then
            echo "OK"
        else
            echo -n "."
        fi
        
        # Remove original BLP file if requested
        if [[ "$REMOVE_BLP" == true ]]; then
            rm -f "$blp_file"
        fi
    else
        ((total_failed++))
        failed_files+=("$rel_path")
        
        if [[ "$VERBOSE" == true ]]; then
            echo "FAILED"
        else
            echo -n "x"
        fi
    fi
done

# New line after progress dots
if [[ "$VERBOSE" == false ]]; then
    echo ""
fi

# Display results
echo ""
echo "Conversion complete!"
echo "Total files converted: $total_converted"
echo "Total files failed: $total_failed"

if [[ $total_failed -gt 0 ]]; then
    echo ""
    echo "Failed conversions:"
    for failed_file in "${failed_files[@]}"; do
        echo "  - $failed_file"
    done
fi

exit 0