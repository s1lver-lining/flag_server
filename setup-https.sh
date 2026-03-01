#!/bin/bash

# HTTPS Setup Script for CTF Platform
# This script helps configure Nginx and Let's Encrypt SSL certificates

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "╔════════════════════════════════════════════════════════════╗"
echo "║         🔒 CTF Platform HTTPS Setup Script 🔒            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}❌ This script must be run as root (use sudo)${NC}"
    exit 1
fi

# Get domain name
echo -e "${BLUE}Enter your domain name (e.g., ctf.example.com):${NC}"
read -r DOMAIN

if [ -z "$DOMAIN" ]; then
    echo -e "${RED}❌ Domain name is required${NC}"
    exit 1
fi

# Get email for Let's Encrypt
echo -e "${BLUE}Enter your email address for Let's Encrypt notifications:${NC}"
read -r EMAIL

if [ -z "$EMAIL" ]; then
    echo -e "${RED}❌ Email is required${NC}"
    exit 1
fi

# Detect OS and install packages
echo ""
echo -e "${YELLOW}📦 Installing Nginx and Certbot...${NC}"

if [ -f /etc/debian_version ]; then
    # Ubuntu/Debian
    apt update
    apt install -y nginx certbot python3-certbot-nginx
elif [ -f /etc/redhat-release ]; then
    # CentOS/RHEL
    yum install -y epel-release
    yum install -y nginx certbot python3-certbot-nginx
    systemctl enable nginx
elif [ -f /etc/arch-release ]; then
    # Arch Linux
    pacman -S --noconfirm nginx certbot certbot-nginx
    systemctl enable nginx
else
    echo -e "${RED}❌ Unsupported OS. Please install Nginx and Certbot manually.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Packages installed${NC}"

# Create Nginx configuration
echo ""
echo -e "${YELLOW}🔧 Creating Nginx configuration...${NC}"

NGINX_CONFIG="/etc/nginx/sites-available/ctf-platform"
if [ -d "/etc/nginx/conf.d" ]; then
    NGINX_CONFIG="/etc/nginx/conf.d/ctf-platform.conf"
fi

cat > "$NGINX_CONFIG" << EOF
server {
    listen 80;
    server_name $DOMAIN;

    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }

    location / {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        
        # WebSocket support
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Headers
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
EOF

# Enable site (for Debian/Ubuntu)
if [ -d "/etc/nginx/sites-enabled" ]; then
    ln -sf "$NGINX_CONFIG" /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
fi

# Test Nginx configuration
echo ""
echo -e "${YELLOW}🧪 Testing Nginx configuration...${NC}"
nginx -t

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Nginx configuration test failed${NC}"
    exit 1
fi

# Start Nginx
echo ""
echo -e "${YELLOW}🚀 Starting Nginx...${NC}"
systemctl restart nginx
systemctl enable nginx

echo -e "${GREEN}✅ Nginx configured and started${NC}"

# Open firewall ports
echo ""
echo -e "${YELLOW}🔥 Configuring firewall...${NC}"

if command -v ufw &> /dev/null; then
    ufw allow 'Nginx Full'
    ufw --force enable
elif command -v firewall-cmd &> /dev/null; then
    firewall-cmd --permanent --add-service=http
    firewall-cmd --permanent --add-service=https
    firewall-cmd --reload
fi

echo -e "${GREEN}✅ Firewall configured${NC}"

# Obtain SSL certificate
echo ""
echo -e "${YELLOW}🔒 Obtaining SSL certificate from Let's Encrypt...${NC}"
echo -e "${BLUE}This may take a few moments...${NC}"

certbot --nginx -d "$DOMAIN" --email "$EMAIL" --agree-tos --non-interactive --redirect

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to obtain SSL certificate${NC}"
    echo -e "${YELLOW}Please check:${NC}"
    echo "  1. DNS is correctly pointing to this server"
    echo "  2. Ports 80 and 443 are accessible from the internet"
    echo "  3. No other service is using port 80 or 443"
    exit 1
fi

echo -e "${GREEN}✅ SSL certificate obtained and configured${NC}"

# Test renewal
echo ""
echo -e "${YELLOW}🧪 Testing certificate auto-renewal...${NC}"
certbot renew --dry-run

if [ $? -ne 0 ]; then
    echo -e "${YELLOW}⚠️  Warning: Auto-renewal test failed${NC}"
else
    echo -e "${GREEN}✅ Auto-renewal configured${NC}"
fi

# Final message
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              🎉 HTTPS Setup Complete! 🎉                  ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Your CTF platform is now accessible at:${NC}"
echo -e "  🌐 Main:   ${GREEN}https://$DOMAIN${NC}"
echo -e "  📊 Kiosk:  ${GREEN}https://$DOMAIN/kiosk${NC}"
echo -e "  🔌 API:    ${GREEN}https://$DOMAIN/api${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Start your CTF platform: ./run.sh"
echo "  2. Visit https://$DOMAIN to verify everything works"
echo "  3. Check SSL grade: https://www.ssllabs.com/ssltest/"
echo ""
echo -e "${BLUE}Certificate will auto-renew 30 days before expiry.${NC}"
echo -e "${BLUE}Certificate location: /etc/letsencrypt/live/$DOMAIN/${NC}"
echo ""
