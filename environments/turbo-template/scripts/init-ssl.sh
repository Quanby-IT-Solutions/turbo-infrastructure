#!/usr/bin/env bash
# ──────────────────────────────────────────────
# init-ssl.sh — First-time SSL certificate setup for staging EC2
#
# Usage: ./init-ssl.sh <web-domain> <api-domain> [email]
# Example: ./init-ssl.sh staging.example.com api-staging.example.com admin@example.com
# ──────────────────────────────────────────────
set -euo pipefail

WEB_DOMAIN="${1:?Usage: $0 <web-domain> <api-domain> [email]}"
API_DOMAIN="${2:?Usage: $0 <web-domain> <api-domain> [email]}"
EMAIL="${3:-}"

echo "=========================================="
echo "SSL Certificate Setup (Let's Encrypt)"
echo "=========================================="
echo "Web domain: $WEB_DOMAIN"
echo "API domain: $API_DOMAIN"
echo ""

# Ensure nginx is running (needed for HTTP challenge)
if ! sudo systemctl is-active --quiet nginx; then
  echo "Starting Nginx..."
  sudo systemctl start nginx
fi

# Ensure certbot webroot exists
sudo mkdir -p /var/www/certbot

# Request certificates
CERTBOT_OPTS="--nginx --non-interactive --agree-tos"
if [ -n "$EMAIL" ]; then
  CERTBOT_OPTS="$CERTBOT_OPTS --email $EMAIL"
else
  CERTBOT_OPTS="$CERTBOT_OPTS --register-unsafely-without-email"
fi

echo "── Requesting certificates ──"
sudo certbot $CERTBOT_OPTS -d "$WEB_DOMAIN" -d "$API_DOMAIN"

echo ""
echo "── Verifying auto-renewal ──"
sudo certbot renew --dry-run

echo ""
echo "✅ SSL setup complete!"
echo "   Certificates will auto-renew via systemd timer."
echo "   Next deploy will automatically detect and use HTTPS configs."
