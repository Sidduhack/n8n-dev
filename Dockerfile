# --- Stage 1: The Builder (Downloads the tools) ---
FROM alpine:latest AS builder
RUN apk add --no-cache curl
# Download Cloudflare
RUN curl -L --output /cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 && chmod +x /cloudflared
# Download ttyd (The Terminal tool)
RUN curl -L --output /ttyd https://github.com/tsl0922/ttyd/releases/download/1.7.3/ttyd.x86_64 && chmod +x /ttyd

# --- Stage 2: The Final App Image ---
FROM n8nio/n8n:latest
USER root

# Install curl permanently in the terminal for you to use
RUN apk add --no-cache curl

# Copy the tools we downloaded in Stage 1
COPY --from=builder /cloudflared /usr/local/bin/cloudflared
COPY --from=builder /ttyd /usr/local/bin/ttyd

# Create the startup script
RUN printf "#!/bin/sh\n\
# 1. Start n8n in background\n\
n8n start &\n\
# 2. Start terminal on port 7681\n\
ttyd -p 7681 -c admin:pass123 sh &\n\
sleep 5\n\
# 3. Start the tunnel pointing to the terminal\n\
cloudflared tunnel --url http://localhost:7681\n" > /start.sh \
    && chmod +x /start.sh && chown node:node /start.sh

# Reset Entrypoint and switch to node user
ENTRYPOINT []
USER node

# Networking
ENV N8N_PORT=5678
EXPOSE 5678
CMD ["sh", "/start.sh"]
