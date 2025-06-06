#!/bin/bash

# 1. Make sure it's executable (handled by the worker)

# 2. Define an image name
IMAGE_NAME="font-builder"

# 3. Build the Docker image
echo "Building Docker image: $IMAGE_NAME..."
docker build -t $IMAGE_NAME .

# Check if Docker build was successful
if [ $? -ne 0 ]; then
    echo "Docker build failed. Exiting."
    exit 1
fi

# 4. Create an output directory on the host
OUTPUT_DIR="output_fonts"
mkdir -p $OUTPUT_DIR
echo "Output directory: $(pwd)/$OUTPUT_DIR"

# 5. Iterate through each .glyphs file in the sources directory
echo "Processing .glyphs files from 'sources' directory..."
for glyph_file in sources/*.glyphs; do
    if [ -f "$glyph_file" ]; then
        filename=$(basename "$glyph_file")
        echo "Building font for: $filename"

        # 6. For each .glyphs file, run a Docker container
        docker run --rm \
            -v "$(pwd)/sources":/app/sources:ro \
            -v "$(pwd)/$OUTPUT_DIR":/app/fonts \
            $IMAGE_NAME \
            fontmake -g "/app/sources/$filename" -o ttf variable -o otf --output-dir /app/fonts
        
        if [ $? -ne 0 ]; then
            echo "Error building font for: $filename"
        else
            echo "Successfully built font for: $filename. Output in $OUTPUT_DIR/"
        fi
    else
        echo "No .glyphs files found in sources directory."
        break 
    fi
done

echo "Font building process completed."
