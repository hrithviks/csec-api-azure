# This Dockerfile builds a custom container image for CI/CD jobs, equipped with
# Terraform, Azure CLI, and Flake8.
# The base image is `debian:bullseye-slim`, chosen for its stability, small
# footprint, and robust package management, providing a reliable foundation for
# build environments.

# Stage 1: Builder
# This stage installs all build tools and dependencies. Each tool is installed
# in a separate layer to optimize Docker's layer caching.
FROM debian:bullseye-slim AS builder

# Defines a build-time argument for the Terraform version. This allows for
# easy version customization during the build process.
# Example: docker build --build-arg TERRAFORM_VERSION=1.8.0 .
ARG TERRAFORM_VERSION=1.13.0

# Sets the frontend to noninteractive to prevent apt-get from prompting for
# user input, ensuring the build process is fully automated.
ARG DEBIAN_FRONTEND=noninteractive

# Install essential packages required for subsequent installation steps.
# Combining update, install, and cleanup in one RUN command reduces layer size.
RUN apt-get update && \
    apt-get install -y --no-install-recommends apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    unzip && \
    # Clean up apt cache to keep the layer lean.
    rm -rf /var/lib/apt/lists/*

# Install Azure CLI. This is in a separate layer for better caching.
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Install Terraform. This layer is dependent on TERRAFORM_VERSION.
# A change in the version argument will only invalidate this layer and those after it.
RUN curl -Lo terraform.zip "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" && \
    unzip terraform.zip && \
    mv terraform /usr/local/bin/terraform && \
    rm terraform.zip

# Install flake8 using the pip from the Azure CLI's embedded Python environment.
RUN /opt/az/bin/python3 -m pip install --no-cache-dir flake8

# Stage 2: Final Image
# This stage creates the final, minimal image by copying only the necessary
# artifacts from the builder stage.
FROM debian:bullseye-slim

# Copy the custom entrypoint script from the build context into the final image.
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
# Make the entrypoint script executable.
RUN chmod +x /usr/local/bin/entrypoint.sh

# Copy only the required tools from the builder stage.
COPY --from=builder /usr/local/bin/terraform /usr/local/bin/terraform
COPY --from=builder /usr/bin/az /usr/bin/az
COPY --from=builder /opt/az /opt/az
COPY --from=builder /opt/az/bin/flake8 /usr/local/bin/flake8

# Set the entrypoint to custom script. All commands will now run through this script first.
ENTRYPOINT ["entrypoint.sh"]

# Set the default command to be executed by the entrypoint if no other command is provided.
# Using '/bin/bash' as the default command keeps the container running in interactive mode,
# which is useful for local testing.
CMD ["/bin/bash"]