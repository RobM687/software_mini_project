FROM python:3.9-slim
# swglh/vcf_filter_script:1.0
# This is a base image for the VCF filter script.

# Set the working directory in the container
WORKDIR /app

# Copy the requirements file
COPY ../../requirements.txt /app/requirements.txt

# Install any needed packages specified in requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

# Copy the VCF filter script
COPY ../../scripts/modules/vcf_filter_script.py /app/vcf_filter_script.py
