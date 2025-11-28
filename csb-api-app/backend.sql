/* ----------------------------------------------------------------------------
* Create backend objects for API-Service.
*
* NOTE: This script contains simple DDLs to create backend objects required
*       for the API-Service. In an enterprise grade implementation, advanced
*       features of PostgreSQL must be utilized for "Zero-Trust" policy.
*
* 1. REQUESTS - Main table for maintaining the current state of a request.
* 2. REQUESTS_AUDIT - Audit table for logging all the events.
*/ ----------------------------------------------------------------------------

create type status_enum as enum (
    'success',
    'failed',
    'rollback',
    'queued',
    'in_progress'
);

create table csb_requests (
    correlation_id uuid primary key,
    client_req_id varchar(255) not null,
    status status_enum not null,
    req_time_stamp timestamptz not null default now(),
    last_upd_time_stamp timestamptz,
    cloud_provider varchar(50) not null,
    principal varchar(255) not null,
    action varchar(50) not null,
    entitlement varchar(255) not null,
    account_id varchar(255)
);

create table csb_requests_audit (
    audit_id bigserial primary key,
    correlation_id uuid not null references csb_requests(correlation_id) on delete cascade,
    status status_enum not null,
    audit_timestamp timestamptz not null default now(),
    audit_log text
);