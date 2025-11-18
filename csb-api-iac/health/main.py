"""
A simple Flask web application for monitoring service health.

This application provides a web endpoint that displays the connection status
of dependent services, such as PostgreSQL and Redis. It reads connection
credentials from environment variables and presents the status on a
user-friendly HTML page.
"""

import os
import psycopg2
import redis
from flask import Flask, render_template, jsonify
from datetime import datetime, timezone

# Initialize the Flask app.
app = Flask(__name__, template_folder='.')

def get_postgres_status():
    """Checks the connection to the PostgreSQL database.

    Attempts to establish a connection using credentials from environment
    variables. A successful connection is immediately closed.

    Relies on the following environment variables:
    - POSTGRES_HOST: The database host.
    - POSTGRES_PORT: The database port (defaults to 5432).
    - POSTGRES_USER: The database user.
    - POSTGRES_PASSWORD: The user's password.
    - POSTGRES_DB: The database name.

    Returns:
        tuple[str, str]: A tuple containing the status ('OK' or 'Error')
        and a descriptive message.
    """
    try:
        # Connect to the database
        conn = psycopg2.connect(
            host=os.getenv("POSTGRES_HOST"),
            port=os.getenv("POSTGRES_PORT", 5432),
            user=os.getenv("POSTGRES_USER"),
            password=os.getenv("POSTGRES_PASSWORD"),
            dbname=os.getenv("POSTGRES_DB"),
            connect_timeout=5
        )

        # If connection is successful, close it and return status
        conn.close()
        return "OK", "Connection successful."
    except Exception as e:
        # If connection fails, return error status
        return "Error", str(e)


def get_redis_status():
    """Checks the connection to the Redis cache.

    Attempts to connect and sends a PING command to the Redis server using
    credentials from environment variables.

    Relies on the following environment variables:
    - REDIS_HOST: The Redis host.
    - REDIS_PORT: The Redis port (defaults to 6379).
    - REDIS_PASSWORD: The Redis password.

    Returns:
        tuple[str, str]: A tuple containing the status ('OK' or 'Error')
        and a descriptive message.
    """
    try:

        # Connect to Redis
        r = redis.Redis(
            host=os.getenv("REDIS_HOST"),
            port=os.getenv("REDIS_PORT", 6379),
            password=os.getenv("REDIS_PASSWORD"),
            socket_connect_timeout=5,
            decode_responses=True
        )

        # Ping the server to check the connection
        r.ping()
        return "OK", "Connection successful."
    except Exception as e:
        # If connection fails, return error status
        return "Error", str(e)


@app.route('/')
def health_check():
    """Flask view function that renders the health check status page.

    This function is the main endpoint of the web application. It calls the
    status check functions for all monitored services and passes the results
    to the 'index.html' template for rendering.
    """
    services = {
        "PostgreSQL": get_postgres_status(),
        "Redis": get_redis_status()
    }
    
    last_checked = datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M:%S UTC')
    
    return render_template('index.html', services=services, last_checked=last_checked)


@app.route('/api/status')
def api_status():
    """API endpoint that returns the health status as JSON.

    This endpoint is called by the frontend to dynamically update the status
    without a full page reload.
    """
    services = {
        "PostgreSQL": get_postgres_status(),
        "Redis": get_redis_status()
    }
    last_checked = datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M:%S UTC')

    return jsonify(services=services, last_checked=last_checked)


if __name__ == '__main__':
    # This allows running the app locally for testing
    # In production, a WSGI server like Gunicorn will be used
    app.run(host='0.0.0.0', port=8000, debug=True)