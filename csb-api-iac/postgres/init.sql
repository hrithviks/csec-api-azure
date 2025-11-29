/* ----------------------------------------------------------------------------
 * CSecBridge Database Initialization Script
 *
 * PURPOSE:
 * This script is responsible for bootstrapping the PostgreSQL database schema
 * for the CSecBridge application. It creates all necessary roles, tables,
 * indexes, and permissions required for the services to function.
 *
 * EXECUTION LIFECYCLE:
 * This script is designed to be executed ONLY ONCE, during the very first
 * startup of the PostgreSQL container against an empty data volume. The
 * official PostgreSQL Docker image's entrypoint handles this automatically.
 *
 * STATE MANAGEMENT AND PERSISTENCE:
 * In a Kubernetes environment, this container is deployed as a StatefulSet
 * with a PersistentVolumeClaim. This ensures that the database's data
 * directory (/var/lib/postgresql/data) is stored on a durable, persistent
 * volume outside the container's lifecycle.
 *
 * On subsequent restarts or redeployments, the new container will attach to
 * the existing persistent volume. Since the data directory is not empty, the
 * entrypoint script will SKIP the execution of this init.sql file, thereby
 * preserving the database's state.
 * 
 * NAMING CONVENTIONS:
 * All custom database objects created for this application - users, tables, 
 * indexes etc. should be prefixed with 'csb_' to avoid conflicts and 
 * improve clarity. Columns are excluded from this convention for readability.
 * 
 */ ---------------------------------------------------------------------------

-- Set timezone to UTC for consistency across the application
set timezone = 'utc';

-- Helper procedure to create a role only if it does not already exist.
-- This makes the script idempotent and safe to re-run.
CREATE OR REPLACE PROCEDURE create_role_if_not_exists(role_name text)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = role_name) THEN
        EXECUTE format('CREATE ROLE %I WITH LOGIN', role_name);
    END IF;
END;
$$;

-- Create roles idempotently using the helper procedure.
CALL create_role_if_not_exists('csb_app');
CALL create_role_if_not_exists('csb_api_user');
CALL create_role_if_not_exists('csb_aws_user');
CALL create_role_if_not_exists('csb_azure_user');

-- Grant connect privileges. (Idempotent by nature).
-- The database name 'csb_app_db' is assumed to be stable for this project.
GRANT CONNECT ON DATABASE csb_app_db TO csb_app;
GRANT CONNECT ON DATABASE csb_app_db TO csb_api_user;
GRANT CONNECT ON DATABASE csb_app_db TO csb_aws_user;
GRANT CONNECT ON DATABASE csb_app_db TO csb_azure_user;

-- Main App Schema, tied to App Role
CREATE SCHEMA IF NOT EXISTS csb_app AUTHORIZATION csb_app;

-- Grant schema privileges. (Idempotent by nature).
GRANT CREATE ON SCHEMA public TO csb_app;
grant usage, create on schema csb_app to csb_app;
grant usage on schema public to csb_api_user;
grant usage on schema csb_app to csb_api_user;
grant usage on schema public to csb_aws_user;
grant usage on schema csb_app to csb_aws_user;
grant usage on schema public to csb_azure_user;
grant usage on schema csb_app to csb_azure_user;

-- Explicitly REVOKE all other permissions to enforce least privilege.
-- REVOKE commands do not error if the privilege is not granted, so they are safe to re-run.
revoke truncate, delete, references, trigger on all tables in schema public from csb_api_user;
revoke truncate, delete, references, trigger on all tables in schema csb_app from csb_api_user;

revoke truncate, delete, references, trigger on all tables in schema public from csb_aws_user;
revoke truncate, delete, references, trigger on all tables in schema csb_app from csb_aws_user;

revoke truncate, delete, references, trigger on all tables in schema public from csb_azure_user;
revoke truncate, delete, references, trigger on all tables in schema csb_app from csb_azure_user;

-- Set search path for the roles. ALTER ROLE is idempotent.
alter role csb_app set search_path = csb_app, public;
alter role csb_api_user set search_path = csb_app, public;
alter role csb_aws_user set search_path = csb_app, public;
alter role csb_azure_user set search_path = csb_app, public;

-- Log a message to the console upon successful completion
\echo 'CSecBridge database initialization script completed successfully.'