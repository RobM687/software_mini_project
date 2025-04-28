FROM ubuntu:20.04
# swglh/picard:1.1
# This is a base image for the Picard tools.
# Setting the working directory in the container to /app
WORKDIR /app

# Install the required dependencies
RUN apt-get update && apt-get install -y \
    # Updated from openjdk-11-jre to openjdk-17-jre, as picard 3.4.0 requires Java 17 or higher.
    openjdk-17-jre \
    wget \
    # Steps to clean up the docker image, removing unnecessary packages and config files.
    && apt-get clean \
    && apt-get purge \
    && rm -rf /var/lib/apt/lists/* /tmp/*


# Download Picard tools
# 'chmod' is not required to make picard.jar executable as executed by 'java -jar' command, JAR file itself doesn't need executable permissions for this. 
RUN wget -O /app/picard.jar https://github.com/broadinstitute/picard/releases/download/3.4.0/picard.jar

# Entrypoint removed as the are problematic when run in DNA Nexus, previously; ENTRYPOINT ["java", "-jar", "/app/picard.jar"]