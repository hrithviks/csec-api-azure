# cSecBridge API Service Application

This directory contains the source code for the `csb-api-app`, a simple Python Flask-based REST API. This application serves as the reference workload for the `cSecBridge-AZ` project, demonstrating how a containerized web service can be securely deployed on Azure.

## Overview

The application is designed as a simple, stateless API that receives requests, persists them to a database, and places them on a queue for asynchronous processing. It also provides an endpoint to check the status of a request.

The core functionality demonstrates a common web application pattern:

1.  **Request Ingestion**: A `POST` endpoint accepts new requests.
2.  **Data Persistence**: The request is immediately saved to an **Azure Database for PostgreSQL** to ensure durability.
3.  **Caching & Queuing**: A **Redis** instance is used for two purposes:
    *   **Queue**: The new request is pushed onto a Redis list, which acts as a simple message queue for a background worker.
    *   **Cache**: The status of the request is cached in Redis to provide fast read access via a `GET` endpoint (Cache-Aside Pattern).

This application is intended purely as a demonstration and is not a feature-complete product.

## Technology Stack

-   **Language**: Python 3
-   **Framework**: Flask
-   **WSGI Server**: Gunicorn
-   **Database Connector**: `psycopg2-binary` (for PostgreSQL)
-   **Cache/Queue Connector**: `redis`
-   **Containerization**: Docker

## Configuration

The application is configured entirely through environment variables. This is a cloud-native best practice that allows the same container image to be deployed across different environments (dev, prod) without any code changes.

The Terraform configuration in the `csb-api-iac` directory is responsible for injecting these variables into the Azure App Service environment.

| Environment Variable  | Description                                          |
| --------------------- | ---------------------------------------------------- |
| `API_AUTH_TOKEN`      | A secret token for authenticating API requests.      |
| `POSTGRES_HOST`       | The hostname of the PostgreSQL server.               |
| `POSTGRES_PORT`       | The port for the PostgreSQL server.                  |
| `POSTGRES_USER`       | The username for the database connection.            |
| `POSTGRES_PASSWORD`   | The password for the database connection.            |
| `POSTGRES_DB`         | The name of the database to connect to.              |
| `REDIS_HOST`          | The hostname or IP address of the Redis cache.       |
| `REDIS_PORT`          | The port for the Redis cache.                        |
| `REDIS_USER`          | The username for the Redis cache.                    |
| `REDIS_PASSWORD`      | The password for the Redis cache.                    |
| `CACHE_TTL_SECONDS`   | The Time-To-Live (TTL) for cache entries in seconds. |
| `ALLOWED_ORIGIN`      | The CORS allowed origin for frontend applications.   |

### A Note on Security

For the simplicity of this demonstration project, secrets such as `API_AUTH_TOKEN` and database passwords (`POSTGRES_PASSWORD` and `REDIS_PASSWORD`) are injected directly into the App Service as environment variables.

**This is not a recommended practice for production environments.**

In a production scenario, these secrets should be stored securely in **Azure Key Vault**. The application would then use its **Managed Identity** to authenticate with Key Vault and retrieve the secrets at runtime. This approach follows the principle of least privilege and eliminates the need to store credentials directly in the application's configuration, utilizing the right the security posture.

## Running the Application

While this application is designed to be deployed via the project's CI/CD pipelines, it can be built and run locally using Docker, provided the necessary environment variables are set.