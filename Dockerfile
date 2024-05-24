FROM stremio/server:v4.20.8

# Define the build argument for the Stremio Web version
ARG STREMIO_WEB_VERSION=v5.0.0-beta.8

# Install dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    bash \
    git \
    nginx \
    openvpn \
    apache2-utils \
    curl \
    unzip \
    ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Create directories for Nginx
RUN mkdir -p /run/nginx /etc/nginx/sites

# Add Nginx configuration files
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/default.conf /etc/nginx/sites/default.conf

# Expose port for Nginx
EXPOSE 80

# Download and unzip the specific version of Stremio Web
WORKDIR /stremio-web
RUN curl -L "https://github.com/stremio/stremio-web/releases/download/${STREMIO_WEB_VERSION}/stremio-web.zip" -o stremio-web.zip \
    && unzip stremio-web.zip \
    && rm stremio-web.zip

# Copy over the entrypoint script
COPY run.sh /run.sh
RUN chmod +x /run.sh

# Set the entrypoint
ENTRYPOINT ["/run.sh"]
