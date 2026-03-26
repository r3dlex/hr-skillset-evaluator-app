FROM python:3.12-slim

# Install Node.js 20 for archgate
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl gnupg && \
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Poetry
RUN pip install --no-cache-dir poetry==1.8.2

WORKDIR /build

# Copy dependency files first (layer caching)
COPY pyproject.toml poetry.lock* ./

# Install dependencies without creating a venv
RUN poetry config virtualenvs.create false && \
    poetry install --no-interaction --no-ansi --no-root

# Copy source code
COPY . .

# Install the package itself into system site-packages
RUN pip install --no-cache-dir .

# Install archgate globally
RUN npm install -g archgate

WORKDIR /workspace

CMD ["python", "-m", "pipeline_runner"]
