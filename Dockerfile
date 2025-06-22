# 1. Start from a suitable Python base image
FROM python:3.9-slim

# 2. Set a working directory
WORKDIR /app

# 3. Install necessary packages including fontforge and python3-fontforge
RUN apt-get update && apt-get install -y --no-install-recommends \
    fontforge \
    python3-fontforge \
    python3-argparse && \
    pip install fontmake gftools && \
    rm -rf /var/lib/apt/lists/*

# 5. Copy the sources directory from the host into the image
COPY sources /app/sources 
COPY FontPatcher /app/FontPatcher

# 6. Create an output directory for the fonts
RUN mkdir -p /app/fonts

# 7. Define a default command
CMD ["ls", "-R", "/app"]
