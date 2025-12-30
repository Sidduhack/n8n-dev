# --- Stage 1: Download Tools ---
FROM alpine:latest AS builder
RUN apk add --no-cache curl
# Download LocalXpose
RUN curl -L --output /loclx https://localxpose.io/download/loclx-linux-amd64 && chmod +x /loclx
# Download ttyd (for the terminal)
RUN curl -L --output /ttyd https://github.com/tsl0922/ttyd/releases/download/1.7.3/ttyd.x86_64 && chmod +x /ttyd

# --- Stage 2: Final n8n image ---
FROM n8nio/n8n:latest
USER root

COPY --from=builder /loclx /usr/local/bin/loclx
COPY --from=builder /ttyd /usr/local/bin/ttyd

# Create the start script
RUN printf "#!/bin/sh\n\
# 1. Start n8n in background\n\
n8n start &\n\
# 2. Start terminal on port 7681\n\
ttyd -p 7681 -c admin:pass123 sh &\n\
sleep 5\n\
# 3. Start the Tunnel (Using the token from Render Environment)\n\
loclx account login --token \${LOCLX_TOKEN}\n\
loclx tunnel http --to 127.0.0.1:5678\n" > /start.sh \
    && chmod +x /start.sh && chown node:node /start.sh

ENTRYPOINT []
USER node
ENV N8N_PORT=5678
EXPOSE 5678
CMD ["sh", "/start.sh"]
