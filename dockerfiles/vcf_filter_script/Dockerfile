FROM debian:latest
# swglh/vcf_filter_script:1.1
# This is a base image for the VCF filter script.

# Install Python, pip, and build dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    build-essential \
    libbz2-dev \
    liblzma-dev \
    libffi-dev \
    libssl-dev \
    zlib1g-dev \
    curl \
    && apt-get clean

# Set the working directory in the container
WORKDIR /app

# Copy the specific requirements.txt file for this Docker image
COPY requirements.txt /app/requirements.txt

# Install any needed packages specified in requirements.txt
RUN pip3 install --no-cache-dir -r /app/requirements.txt

# Copy the VCF filter script
COPY vcf_filter_script.py /app/vcf_filter_script.py
