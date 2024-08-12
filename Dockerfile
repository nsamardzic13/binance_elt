FROM python:3.11-slim-bullseye

# Install OS dependencies
RUN apt-get update && apt-get install -qq -y \
    git gcc build-essential libpq-dev --fix-missing --no-install-recommends \
    && apt-get clean

# Make sure we are using latest pip
RUN pip install --upgrade pip

# Create directory for dbt config
RUN mkdir -p /root/.dbt

# Install dependencies
RUN pip install dbt-core dbt-bigquery

# Copy source code
COPY dbt_binance/ .

RUN chmod -R 755 scripts/

# we run everything through sh, so we can execute all we'd like
ENTRYPOINT [ "/bin/sh", "-c" ]
CMD ["scripts/dbt_container_init_commands.sh"]