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
ARG TERRAFORM_VERSION=1.14.0

# Defines a build-time argument for the PostgreSQL client version.
# Example: docker build --build-arg POSTGRES_CLIENT_VERSION=16 .
ARG POSTGRES_CLIENT_VERSION=16

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
    wget \
    unzip \
    jq \
    redis-tools

# Install PostgreSQL client. This is in a separate layer for better caching.
RUN apt-get update && \
    echo "deb [signed-by=/usr/share/keyrings/postgresql-archive-keyring.gpg] http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
    curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /usr/share/keyrings/postgresql-archive-keyring.gpg && \
    apt-get update && \
    apt-get install -y --no-install-recommends "postgresql-client-${POSTGRES_CLIENT_VERSION}" && \
    rm -rf /var/lib/apt/lists/*

# Install Docker CLI. This allows the container to execute docker commands
# by communicating with the host's Docker daemon via a mounted socket.
RUN install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc && \
    chmod a+r /etc/apt/keyrings/docker.asc && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get install -y docker-ce-cli

# Install Azure CLI. This is in a separate layer for better caching.
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Install Terraform. This layer is dependent on TERRAFORM_VERSION.
# A change in the version argument will only invalidate this layer and those after it.
RUN curl -Lo terraform.zip "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" && \
    unzip terraform.zip && \
    mv terraform /usr/local/bin/terraform && \
    rm terraform.zip

# Install flake8 using the pip from the Azure CLI's embedded Python environment.
RUN /opt/az/bin/python3 -m pip install --no-cache-dir flake8 bandit

# Install Terraform SAST tools: tflint and tfsec.
# These are installed in a single layer to keep the image clean.
RUN set -e && \
    # Install Trivy for vulnerability scanning by downloading the binary archive
    TRIVY_VERSION=$(curl -s "https://api.github.com/repos/aquasecurity/trivy/releases/latest" | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/') && \
    wget "https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz" && \
    tar -zxvf "trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz" trivy && \
    mv trivy /usr/local/bin/trivy && \
    # Install tflint for Terraform linting
    curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash && \
    # Install tfsec for Terraform security scanning
    curl -s https://raw.githubusercontent.com/aquasecurity/tfsec/master/scripts/install_linux.sh | bash

# Stage 2: Final Image
# This stage creates the final, minimal image by copying only the necessary
# artifacts from the builder stage.
FROM debian:bullseye-slim

# Copy the updated CA certificates from the builder stage to ensure the final
# image can trust external TLS endpoints.
COPY --from=builder /etc/ssl/certs/ /etc/ssl/certs/
# Copy the custom entrypoint script from the build context into the final image.
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
# Make the entrypoint script executable.
RUN chmod +x /usr/local/bin/entrypoint.sh

# Defines a build-time argument for the PostgreSQL client version for the final image.
ARG POSTGRES_CLIENT_VERSION=16

# Install PostgreSQL client in the final image to ensure all dependencies are present.
# Also install jq and redis-tools to ensure their binaries and shared libraries are available.
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl gnupg lsb-release jq redis-tools && \
    echo "deb [signed-by=/usr/share/keyrings/postgresql-archive-keyring.gpg] http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
    curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /usr/share/keyrings/postgresql-archive-keyring.gpg && \
    apt-get update && \
    apt-get install -y --no-install-recommends "postgresql-client-${POSTGRES_CLIENT_VERSION}" && \
    rm -rf /var/lib/apt/lists/*

# Copy only the required tools from the builder stage.
COPY --from=builder /usr/local/bin/terraform /usr/local/bin/terraform
COPY --from=builder /usr/bin/az /usr/bin/az
COPY --from=builder /opt/az /opt/az
COPY --from=builder /opt/az/bin/flake8 /usr/local/bin/flake8
COPY --from=builder /opt/az/bin/bandit /usr/local/bin/bandit
COPY --from=builder /usr/local/bin/tflint /usr/local/bin/tflint
COPY --from=builder /usr/local/bin/tfsec /usr/local/bin/tfsec
COPY --from=builder /usr/bin/docker /usr/bin/docker
COPY --from=builder /usr/local/bin/trivy /usr/local/bin/trivy

# Set the entrypoint to custom script. All commands will now run through this script first.
ENTRYPOINT ["entrypoint.sh"]

# Set the default command to be executed by the entrypoint if no other command is provided.
# Using '/bin/bash' as the default command keeps the container running in interactive mode,
# which is useful for local testing.
CMD ["/bin/bash"]