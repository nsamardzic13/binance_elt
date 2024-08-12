FROM python:3.11-slim

# Install OS dependencies
RUN apt-get update && apt-get install -qq -y \
    git gcc build-essential libpq-dev --fix-missing --no-install-recommends \
    && apt-get clean

# Make sure we are using latest pip
RUN pip install --upgrade pip
# Install dependencies
RUN pip install dbt-core dbt-bigquery

# Create directory for dbt config
RUN mkdir -p /root/.dbt

# Copy source code
COPY dbt_binance/ dbt_binance/
COPY scripts/ scripts/

RUN chmod -R 755 scripts/

# we run everything through sh, so we can execute all we'd like
ENTRYPOINT [ "/bin/sh", "-c" ]
CMD ["scripts/run_dbt.sh"]