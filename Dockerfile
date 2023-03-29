
FROM postgres:15


# Set environment variables for database name, user, and password
ENV POSTGRES_DB a11y
ENV POSTGRES_USER a11yPython
ENV POSTGRES_PASSWORD SnakeInTheWeb
ENV POSTGRES_PORT 5432

# Copy the dump file to the container and restore the schema and functions
COPY a11ydb.sql /docker-entrypoint-initdb.d/




