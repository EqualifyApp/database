
FROM postgres:15


# Set env vars for default user
ENV POSTGRES_DB a11ydata
ENV POSTGRES_USER a11ydata
ENV POSTGRES_PASSWORD a11yAllTheThings!
ENV POSTGRES_PORT 5432




# Copy the dump file to the container and restore the schema and functions
COPY baby_a11yphant.sql /docker-entrypoint-initdb.d/


# Mount as storage location: /var/lib/postgresql/data

