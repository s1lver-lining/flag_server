# HTTPS Setup Guide

This guide explains how to enable HTTPS for your CTF platform using Let's Encrypt and Nginx.

## Prerequisites

- A domain name pointing to your server (e.g., `fvm.francecentral.cloudapp.azure.com`)
- Server with a public IP address
- Port 80 and 443 accessible from the internet

## Architecture

```
Internet → Nginx (Port 443 HTTPS) → Flask Backend (Port 5000)
           Nginx (Port 80 HTTP)    → Redirect to HTTPS
```

## Installation Steps

### 1. Install Nginx and Certbot

**On Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install -y nginx certbot python3-certbot-nginx
```

**On CentOS/RHEL:**
```bash
sudo yum install -y nginx certbot python3-certbot-nginx
sudo systemctl enable nginx
```

**On Arch Linux:**
```bash
sudo pacman -S nginx certbot certbot-nginx
sudo systemctl enable nginx
```

### 2. Configure Nginx (Before SSL)

Create initial Nginx configuration:

```bash
sudo nano /etc/nginx/sites-available/ctf-platform
```

Add this configuration (replace `fvm.francecentral.cloudapp.azure.com` with your domain):

```nginx
server {
    listen 80;
    server_name fvm.francecentral.cloudapp.azure.com;

    # For Let's Encrypt verification
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }

    location / {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        
        # WebSocket support
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Headers
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
```

Enable the site:

```bash
# On Ubuntu/Debian
sudo ln -s /etc/nginx/sites-available/ctf-platform /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default  # Remove default site

# On CentOS/RHEL/Arch
sudo cp /etc/nginx/sites-available/ctf-platform /etc/nginx/conf.d/ctf-platform.conf
```

Test and reload Nginx:

```bash
sudo nginx -t
sudo systemctl restart nginx
```

### 3. Obtain SSL Certificate

Run Certbot to get a free SSL certificate:

```bash
sudo certbot --nginx -d fvm.francecentral.cloudapp.azure.com
```

Follow the prompts:
- Enter your email address
- Agree to Terms of Service
- Choose whether to redirect HTTP to HTTPS (recommended: Yes)

Certbot will automatically:
- Obtain the SSL certificate
- Modify your Nginx configuration
- Set up automatic renewal

### 4. Final Nginx Configuration

After Certbot, your configuration will look like this:

```nginx
server {
    listen 80;
    server_name fvm.francecentral.cloudapp.azure.com;
    
    # Redirect all HTTP to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name fvm.francecentral.cloudapp.azure.com;

    # SSL Certificate paths (added by Certbot)
    ssl_certificate /etc/letsencrypt/live/fvm.francecentral.cloudapp.azure.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/fvm.francecentral.cloudapp.azure.com/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Rate limiting
    limit_req_zone $binary_remote_addr zone=ctf_limit:10m rate=10r/s;
    limit_req zone=ctf_limit burst=20 nodelay;

    # Max upload size
    client_max_body_size 10M;

    location / {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        
        # WebSocket support
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Headers
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Static files caching
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|woff|woff2)$ {
        proxy_pass http://localhost:5000;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

### 5. Start Your CTF Platform

```bash
cd /path/to/fvm_ctf
./run.sh
```

Or use systemd service (recommended for production):

```bash
sudo systemctl start ctf-platform
sudo systemctl enable ctf-platform
```

### 6. Test HTTPS

Visit your site:
```
https://fvm.francecentral.cloudapp.azure.com
```

Check SSL configuration:
```bash
curl -I https://fvm.francecentral.cloudapp.azure.com
```

### 7. Automatic Certificate Renewal

Certbot automatically sets up a cron job or systemd timer for renewal. Test it:

```bash
sudo certbot renew --dry-run
```

Check renewal timer:
```bash
sudo systemctl list-timers | grep certbot
```

## Firewall Configuration

Make sure ports are open:

```bash
# UFW (Ubuntu)
sudo ufw allow 'Nginx Full'
sudo ufw allow OpenSSH
sudo ufw enable

# firewalld (CentOS/RHEL)
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload

# iptables
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT
sudo iptables-save > /etc/iptables/rules.v4
```

## Update run.sh for Production

Modify the environment variable to only bind to localhost (since Nginx is now the public-facing server):

```bash
# In run.sh, change:
gunicorn --worker-class eventlet -w $WORKERS \
    --bind 127.0.0.1:$PORT \
    --access-logfile - \
    --error-logfile - \
    app:app &
```

This ensures Flask only listens on localhost, not on the public interface.

## Troubleshooting

### Certificate Not Working

```bash
# Check Nginx error log
sudo tail -f /var/log/nginx/error.log

# Test Nginx configuration
sudo nginx -t

# Check certificate status
sudo certbot certificates
```

### WebSocket Issues

Make sure these headers are present:
```nginx
proxy_set_header Upgrade $http_upgrade;
proxy_set_header Connection "upgrade";
```

### Rate Limiting Too Strict

Adjust in Nginx config:
```nginx
limit_req_zone $binary_remote_addr zone=ctf_limit:10m rate=50r/s;
limit_req zone=ctf_limit burst=100 nodelay;
```

### Check Backend is Running

```bash
curl http://localhost:5000/api/challenges
```

## Security Best Practices

1. **Keep certificates updated**: Certbot handles this automatically
2. **Enable HSTS**: Already included in config above
3. **Use strong SSL configuration**: Certbot provides this
4. **Rate limiting**: Protect against DDoS attacks
5. **Regular updates**: Keep Nginx and Certbot updated

```bash
sudo apt update && sudo apt upgrade -y  # Ubuntu/Debian
sudo yum update -y                       # CentOS/RHEL
sudo pacman -Syu                         # Arch Linux
```

## SSL Grade Check

Test your SSL configuration:
- https://www.ssllabs.com/ssltest/
- https://securityheaders.com/

Target: **A+ rating**

## Multiple Domains

To add multiple domains (e.g., www.fvm.francecentral.cloudapp.azure.com):

```bash
sudo certbot --nginx -d fvm.francecentral.cloudapp.azure.com -d www.fvm.francecentral.cloudapp.azure.com
```

## Monitoring Certificate Expiry

Let's Encrypt certificates expire after 90 days. Certbot auto-renews them 30 days before expiry.

Check expiry:
```bash
sudo certbot certificates
```

Manual renewal:
```bash
sudo certbot renew
sudo systemctl reload nginx
```

## Complete Production Setup Checklist

- [ ] Domain name configured and pointing to server
- [ ] Nginx installed
- [ ] Certbot installed
- [ ] Initial Nginx config created
- [ ] SSL certificate obtained
- [ ] HTTPS working
- [ ] HTTP redirects to HTTPS
- [ ] WebSocket connections work
- [ ] Firewall configured
- [ ] Auto-renewal tested
- [ ] Backend only listens on localhost
- [ ] Systemd service configured
- [ ] Monitoring set up

## Support

Your platform is now running with HTTPS! 🔒

Access:
- Main: https://fvm.francecentral.cloudapp.azure.com
- Kiosk: https://fvm.francecentral.cloudapp.azure.com/kiosk
- API: https://fvm.francecentral.cloudapp.azure.com/api
