# 1. Start from a suitable Python base image
FROM python:3.9-slim

# 2. Set a working directory
WORKDIR /app

# 3. Install fontmake and its dependencies
# It's good practice to also install gftools
RUN pip install fontmake gftools

# 4. Copy the sources directory from the host into the image
COPY sources /app/sources

# 5. Create an output directory for the fonts
RUN mkdir /app/fonts

# 6. Define a default command
CMD ["ls", "-R", "/app"]
