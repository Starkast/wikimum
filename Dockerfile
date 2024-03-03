ARG RUBY_VERSION
FROM registry.docker.com/library/ruby:$RUBY_VERSION-slim as base

# The app lives here
WORKDIR /app

# Install base packages
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    curl \
    postgresql-client

# Set production environment
ENV BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_CACHE_PATH="/usr/local/bundle/cache" \
    BUNDLE_WITHOUT="development"

# Throw-away build stage to reduce size of final image
FROM base as build

# Install build packages
RUN apt-get install --no-install-recommends -y \
    build-essential \
    git \
    libpq-dev \
    pkg-config

# Install application gems
COPY Gemfile Gemfile.lock .ruby-version ./
COPY vendor/cache "${BUNDLE_CACHE_PATH}"
RUN bundle install --local

# Copy application code
COPY . .

# Final stage for app image
FROM base

ARG APPUSER=app
ARG APPDIR=/app

# Clean up installation packages to reduce image size
RUN rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Copy built artifacts: gems, application
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build $APPDIR $APPDIR

# Run and own only the runtime files as a non-root user for security
RUN mkdir -p log tmp
RUN groupadd --system --gid 1000 $APPUSER
RUN useradd $APPUSER --uid 1000 --gid 1000 --create-home --shell /bin/bash
RUN chown -R $APPUSER:$APPUSER log tmp
USER 1000:1000

# Start the server by default, this can be overwritten at runtime
CMD bin/start
