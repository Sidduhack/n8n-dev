# Use the Debian-based n8n image
FROM n8nio/n8n:latest-debian

USER root

# Install curl (using apt-get because this is Debian)
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Download and install the cloudflared binary
RUN curl -L --output /usr/local/bin/cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 && \
    chmod +x /usr/local/bin/cloudflared

# Create a start script to run n8n and the tunnel together
RUN echo '#!/bin/sh\n\
n8n start &\n\
cloudflared tunnel --no-autoupdate run --token ${TUNNEL_TOKEN}' > /start.sh && chmod +x /start.sh

# Render expects the app on port 5678
ENV N8N_PORT=5678
EXPOSE 5678

CMD ["/start.sh"]
