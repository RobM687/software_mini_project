FROM python:3.10-slim
# swglh/vcf_filter_script:1.2
# This is a base image for the VCF filter script.

# Set the working directory in the container
WORKDIR /app

# Copy the specific requirements.txt file for this Docker image
COPY requirements.txt /app/requirements.txt

# Install any needed packages specified in requirements.txt
RUN pip3 install --no-cache-dir -r /app/requirements.txt