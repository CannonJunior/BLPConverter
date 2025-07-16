# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

BLPConverter is a C++ command-line tool that converts BLP (Blizzard Picture) image files used by Blizzard games to standard PNG or TGA formats. The project supports both BLP1 and BLP2 format variants with various compression schemes including JPEG, DXT1/3/5, and uncompressed formats.

## Essential Commands

### Build Commands
```bash
# Standard build process
mkdir build
cd build
cmake ..
make

# Build as library
cmake -DWITH_LIBRARY=YES ..
make

# Build with specific configuration
cmake -DCMAKE_BUILD_TYPE=Release -DWITH_LIBRARY=OFF ..
make
```

### Usage Commands
```bash
# Convert single BLP file to PNG
./BLPConverter input.blp

# Convert multiple files
./BLPConverter file1.blp file2.blp file3.blp

# Convert to TGA format
./BLPConverter -f tga input.blp

# Convert specific mip level
./BLPConverter -m 2 input.blp

# Show file information without converting
./BLPConverter -i input.blp

# Specify output directory
./BLPConverter -o /output/path/ input.blp

# Bulk conversion using Python script (Python 2.x syntax)
python extra/convert_all.py /path/to/blp/files/
```

### Testing Commands
```bash
# Test different build configurations (from .travis.yml)
cmake -DCMAKE_BUILD_TYPE=Debug -DWITH_LIBRARY=OFF .. && make
cmake -DCMAKE_BUILD_TYPE=Debug -DWITH_LIBRARY=ON .. && make
cmake -DCMAKE_BUILD_TYPE=Release -DWITH_LIBRARY=OFF .. && make
cmake -DCMAKE_BUILD_TYPE=Release -DWITH_LIBRARY=ON .. && make
```

## Architecture Overview

### Core Processing Pipeline
The BLP conversion follows a multi-stage pipeline:

1. **Format Detection**: Magic number identification ("BLP1" or "BLP2") 
2. **Header Parsing**: Extract format metadata, dimensions, and mip level information
3. **Format-Specific Decoding**: Route to appropriate converter based on compression type
4. **Pixel Data Generation**: Convert to unified BGRA pixel array format
5. **Output Export**: Use FreeImage to save as PNG/TGA

### Key Components
- **main.cpp**: CLI interface with SimpleOpt argument parsing
- **blp.h/blp.cpp**: Core processing library with C-compatible API
- **blp_internal.h**: Internal data structures for BLP1/BLP2 headers
- **extra/convert_all.py**: Batch processing utility (Python 2.x)

### Format Support Matrix
- **BLP1**: JPEG compression, uncompressed paletted (with/without alpha)
- **BLP2**: Uncompressed paletted, DXT1/3/5 compression, raw BGRA, variable alpha depths (1/4/8-bit)

### Dependencies (Self-Contained)
- **FreeImage 3.13.1**: Image processing and format conversion
- **squish 1.10**: DXT texture compression/decompression
- **SimpleOpt 3.4**: Command-line argument parsing

## Implementation Details

### Memory Management Pattern
- **tBLPInfos**: Opaque handle returned by `blp_processFile()`
- **Pixel Data**: Caller must `delete[]` returned `tBGRAPixel*` arrays
- **Resource Cleanup**: Use `blp_release()` for internal structures
- **FreeImage Lifecycle**: Initialize/deinitialize in main application

### BLP Format Specifics
- **Mipmap Requirements**: Complete chains required down to 1x1 pixel
- **Pixel Format**: Unified BGRA 32-bit output regardless of input format
- **Alpha Handling**: Format-specific alpha channel processing (1-bit, 4-bit, 8-bit)
- **Compression Support**: JPEG (BLP1), DXT1/3/5 (BLP2), uncompressed variants

### Build System Architecture
- **CMake Configuration**: Supports both executable and library targets
- **Conditional Compilation**: `WITH_LIBRARY` option controls build mode
- **Platform Support**: Linux/macOS focused, uses POSIX file operations
- **Dependency Management**: All libraries bundled in `dependencies/` directory

### Error Handling Strategy
- **NULL Returns**: Processing failures return null pointers
- **Console Feedback**: Error messages printed to stderr for user visibility
- **Graceful Degradation**: Continues processing remaining files on individual failures
- **Format Validation**: Magic number verification prevents invalid file processing