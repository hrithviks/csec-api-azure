# Dockerfile to create a custom build agent with Terraform and Azure CLI.

# Stage 1: Builder
# This stage installs all necessary tools and downloads the required binaries.
FROM ubuntu:22.04 AS builder

# Define build-time arguments. This allows the Terraform version to be easily
# customized when building the image
# (e.g., docker build --build-arg TERRAFORM_VERSION=1.8.0).
ARG TERRAFORM_VERSION=1.8.0-1

# Set the frontend to noninteractive to prevent apt-get 
# from prompting for user input during the build.
ARG DEBIAN_FRONTEND=noninteractive

# Install build dependencies required to download and set up tools.
# - ca-certificates: For SSL/TLS certificate validation when downloading from the web.
# - curl: Transfer data from or to a server
# - gnupg: Used to add and verify GPG keys for secure package repositories.
# - lsb-release: Provides Linux Standard Base information, used to identify the OS version for repository setup.
# - unzip: Required for certain dependent packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    unzip

# Install the Azure CLI by downloading and executing the official installation script.
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Install Terraform using the official HashiCorp repository.
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
RUN echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
RUN apt-get update && \
    apt-get install -y terraform=${TERRAFORM_VERSION}

# Stage 2: Final Image
# This stage creates the final, clean image by copying the installed tools and scripts.
FROM ubuntu:22.04

# Set the frontend to noninteractive to prevent apt-get from prompting for user input.
ARG DEBIAN_FRONTEND=noninteractive

# Install the runtime dependencies. 
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy the custom entrypoint script from the build context into the final image.
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

# Make the entrypoint script executable.
RUN chmod +x /usr/local/bin/entrypoint.sh

# Copy the Terraform binary from the builder stage.
COPY --from=builder /usr/bin/terraform /usr/bin/terraform

# Copy the entire Azure CLI installation from the builder stage.
# The Azure CLI is installed across multiple directories.
COPY --from=builder /opt/az/ /opt/az/
COPY --from=builder /usr/bin/az /usr/bin/az

# Set the entrypoint to custom script. All commands will now run through this script first.
ENTRYPOINT ["entrypoint.sh"]

# Set the default command to be executed by the entrypoint if no other command is provided.
# Using '/bin/bash' as the default command keeps the container running in interactive mode,
# allowing you to execute commands inside it. This is useful for local testing.
CMD ["/bin/bash"]