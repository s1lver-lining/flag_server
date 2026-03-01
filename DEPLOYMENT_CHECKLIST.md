# Production Deployment Checklist

## Pre-Deployment

### System Requirements
- [ ] Linux server (Ubuntu 20.04+ or similar)
- [ ] Python 3.8+
- [ ] Node.js 16+
- [ ] 2GB+ RAM
- [ ] 10GB+ disk space
- [ ] Open ports 80, 443 (if using Nginx)

### Security
- [ ] Server firewall configured
- [ ] SSH keys set up (no password auth)
- [ ] Non-root user created
- [ ] UFW/iptables configured
- [ ] Fail2ban installed and configured

## Installation

### 1. Install Dependencies
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Python
sudo apt install python3 python3-pip python3-venv -y

# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install nodejs -y

# Install Nginx (optional but recommended)
sudo apt install nginx -y
```

### 2. Deploy Application
```bash
# Clone/copy application
cd /opt
sudo mkdir ctf-platform
sudo chown $USER:$USER ctf-platform
cd ctf-platform

# Copy files here or git clone
# ...

# Install Python dependencies
pip install -r requirements.txt

# Install frontend dependencies
cd frontend
npm install
cd ..
```

### 3. Configuration
- [ ] Update `data/challenges.json` with your challenges
- [ ] Place `challenges.zip` in `static/` directory
- [ ] Set environment variables for ports if needed
- [ ] Configure CORS settings if using different domain

## Deployment

### Option 1: Simple (Direct Script)
```bash
./run.sh
```

### Option 2: Systemd Service (Recommended)
```bash
# Copy systemd service
sudo cp ctf-platform.service /etc/systemd/system/

# Edit paths in service file
sudo nano /etc/systemd/system/ctf-platform.service

# Enable and start
sudo systemctl daemon-reload
sudo systemctl enable ctf-platform
sudo systemctl start ctf-platform

# Check status
sudo systemctl status ctf-platform
```

### Option 3: Nginx Reverse Proxy (Production)
```bash
# Copy nginx config
sudo cp nginx.conf /etc/nginx/sites-available/ctf-platform

# Edit domain name
sudo nano /etc/nginx/sites-available/ctf-platform

# Enable site
sudo ln -s /etc/nginx/sites-available/ctf-platform /etc/nginx/sites-enabled/

# Test config
sudo nginx -t

# Reload nginx
sudo systemctl reload nginx
```

## Post-Deployment

### Testing
- [ ] Access frontend: http://your-domain.com
- [ ] Test challenge download
- [ ] Submit test flag
- [ ] Check scoreboard updates in real-time
- [ ] Run health check: `./health-check.sh`
- [ ] Test race condition protection: `python3 test_download_counter.py`

### Monitoring
- [ ] Set up log rotation
- [ ] Configure monitoring (Prometheus, Grafana, etc.)
- [ ] Set up alerting
- [ ] Test backup procedures

### Security Hardening
- [ ] Enable HTTPS (Let's Encrypt)
- [ ] Configure rate limiting in Nginx
- [ ] Set up WAF (Web Application Firewall)
- [ ] Enable security headers
- [ ] Regular security updates
- [ ] Implement backup strategy

## SSL/HTTPS Setup (Recommended)

```bash
# Install Certbot
sudo apt install certbot python3-certbot-nginx -y

# Get SSL certificate
sudo certbot --nginx -d ctf.example.com

# Auto-renewal (test)
sudo certbot renew --dry-run
```

## Backup Strategy

### Automated Backup Script
```bash
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backups/ctf"
mkdir -p $BACKUP_DIR

# Backup data
tar -czf $BACKUP_DIR/ctf-data-$DATE.tar.gz \
    /opt/ctf-platform/data/ \
    /opt/ctf-platform/static/challenges.zip

# Keep only last 7 days
find $BACKUP_DIR -name "ctf-data-*.tar.gz" -mtime +7 -delete
```

Add to crontab:
```bash
# Daily backup at 2 AM
0 2 * * * /opt/ctf-platform/backup.sh
```

## Maintenance

### Regular Tasks
- [ ] Weekly security updates
- [ ] Monthly dependency updates
- [ ] Quarterly penetration testing
- [ ] Review logs regularly
- [ ] Monitor disk space
- [ ] Check download stats

### Update Application
```bash
# Stop service
sudo systemctl stop ctf-platform

# Backup current version
cp -r /opt/ctf-platform /opt/ctf-platform.backup

# Update code
cd /opt/ctf-platform
git pull  # or copy new files

# Update dependencies
pip install -r requirements.txt
cd frontend && npm install && cd ..

# Restart service
sudo systemctl start ctf-platform
```

## Troubleshooting

### Service won't start
```bash
# Check logs
sudo journalctl -u ctf-platform -n 50

# Check ports
sudo netstat -tuln | grep -E "(5000|3000)"

# Check permissions
ls -la /opt/ctf-platform/data
```

### High CPU usage
```bash
# Check processes
top -u www-data

# Increase workers
WORKERS=8 ./run.sh
```

### Database corruption
```bash
# Restore from backup
cd /opt/ctf-platform
cp data/scoreboard.json data/scoreboard.json.corrupt
tar -xzf /backups/ctf/ctf-data-YYYYMMDD.tar.gz
```

## Performance Tuning

### Recommended Settings
- **Gunicorn Workers**: `(2 x CPU cores) + 1`
- **Max Connections**: 1000
- **Nginx Worker Processes**: Number of CPU cores
- **Nginx Worker Connections**: 1024

### For High Traffic (1000+ concurrent users)
1. Use Redis for session storage
2. Implement PostgreSQL instead of JSON
3. Set up load balancer
4. Use CDN for static assets
5. Enable caching
6. Horizontal scaling

## Rollback Plan

If deployment fails:
```bash
# Stop new version
sudo systemctl stop ctf-platform

# Restore backup
sudo rm -rf /opt/ctf-platform
sudo mv /opt/ctf-platform.backup /opt/ctf-platform

# Start old version
sudo systemctl start ctf-platform
```

## Contact & Support

For issues or questions:
1. Check logs: `sudo journalctl -u ctf-platform`
2. Run health check: `./health-check.sh`
3. Check documentation in this repository

## Success Criteria

Deployment is successful when:
- [x] Platform accessible via browser
- [x] SSL/HTTPS enabled
- [x] All features working (submit, scoreboard, download)
- [x] Real-time updates working (WebSocket)
- [x] Backups configured
- [x] Monitoring active
- [x] Health checks passing
- [x] Performance acceptable
