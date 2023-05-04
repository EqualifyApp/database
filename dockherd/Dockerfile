# Set image to Postgres:15
FROM postgres:15

# Set env vars for default user
ENV POSTGRES_DB a11ydata
ENV POSTGRES_USER a11ydata
ENV POSTGRES_PASSWORD a11yAllTheThings!
ENV POSTGRES_PORT 5432

# Copy the schema and import SQL files to the container
# Setup the databases
COPY baby_a11yphant.sql /docker-entrypoint-initdb.d/01_setup.sql

# Seed with initial data
COPY child_a11yphant.sql /docker-entrypoint-initdb.d/02_import_data.sql

# Copy data files over
COPY start_urls.csv /docker-entrypoint-initdb.d/
COPY start_domains.csv /docker-entrypoint-initdb.d/

