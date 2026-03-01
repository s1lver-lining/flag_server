# Production Deployment Guide

## Quick Start (Simple)

Just run the production script:

```bash
./run.sh
```

Press `Ctrl+C` to stop both frontend and backend gracefully.

## Configuration

You can configure ports and workers via environment variables:

```bash
# Custom configuration
BACKEND_PORT=8000 FRONTEND_PORT=8080 WORKERS=8 ./run.sh
```

**Environment Variables:**
- `BACKEND_PORT` - Backend API port (default: 5000)
- `FRONTEND_PORT` - Frontend server port (default: 3000)
- `WORKERS` - Number of Gunicorn workers (default: 4)

## What It Does

1. ✅ Checks dependencies (Python, Node.js)
2. ✅ Installs missing packages
3. ✅ Builds frontend for production
4. ✅ Starts backend with Gunicorn + Eventlet (production WSGI server)
5. ✅ Starts frontend with Python HTTP server
6. ✅ Gracefully shuts down both when stopped

## Production Features

### Backend (Gunicorn + Eventlet)
- **Production-ready WSGI server** (not Flask dev server)
- **WebSocket support** via Eventlet worker class
- **Process management** - restarts on failure
- **Logging** to stdout/stderr

### Frontend
- **Optimized build** - minified, bundled assets
- **Static file serving** via Python's http.server
- **Fast loading** - production-optimized

## Systemd Service (Optional)

For production servers, you can set up a systemd service:

### 1. Copy files to /opt
```bash
sudo cp -r . /opt/ctf-platform
sudo chown -R www-data:www-data /opt/ctf-platform
```

### 2. Create virtual environment
```bash
cd /opt/ctf-platform
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### 3. Install systemd service
```bash
sudo cp ctf-platform.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable ctf-platform
sudo systemctl start ctf-platform
```

### 4. Check status
```bash
sudo systemctl status ctf-platform
```

### 5. View logs
```bash
sudo journalctl -u ctf-platform -f
```

## Nginx Reverse Proxy (Recommended)

For production, use Nginx as a reverse proxy:

### nginx.conf
```nginx
server {
    listen 80;
    server_name ctf.example.com;

    # Frontend
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }

    # Backend API
    location /api/ {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }

    # WebSocket
    location /socket.io/ {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

## Docker Deployment (Alternative)

See `Dockerfile` and `docker-compose.yml` for containerized deployment.

## Monitoring

### Health Check Endpoints
```bash
# Backend health
curl http://localhost:5000/api/scoreboard

# Download stats
curl http://localhost:5000/api/download-stats
```

### Process Monitoring
```bash
# Check running processes
ps aux | grep -E "(gunicorn|python.*http.server)"

# Check ports
netstat -tuln | grep -E "(5000|3000)"
```

## Troubleshooting

### Port already in use
```bash
# Find process using port 5000
lsof -i :5000

# Kill it
kill -9 <PID>
```

### Frontend build fails
```bash
cd frontend
rm -rf node_modules dist
npm install
npm run build
```

### Backend won't start
```bash
# Check Python dependencies
pip install -r requirements.txt

# Test manually
gunicorn --worker-class eventlet -w 1 --bind 0.0.0.0:5000 app:app
```

## Security Considerations

1. **Change default ports** in production
2. **Use HTTPS** with SSL certificates (Let's Encrypt)
3. **Set up firewall** rules
4. **Regular backups** of `data/` directory
5. **Monitor logs** for suspicious activity
6. **Rate limiting** via Nginx
7. **Keep dependencies updated**

## Performance Tuning

### Gunicorn Workers
```bash
# Calculate optimal workers: (2 x CPU cores) + 1
# For 4 cores: 9 workers
WORKERS=9 ./run.sh
```

### Frontend Optimization
The production build automatically:
- Minifies JavaScript/CSS
- Optimizes images
- Enables tree-shaking
- Generates source maps

## Backup & Recovery

### Backup data
```bash
tar -czf ctf-backup-$(date +%Y%m%d).tar.gz data/ static/challenges.zip
```

### Restore data
```bash
tar -xzf ctf-backup-20260301.tar.gz
```

## Scaling

For high traffic:
1. Use multiple Gunicorn workers
2. Add Redis for session storage
3. Use PostgreSQL instead of JSON files
4. Implement caching (Redis/Memcached)
5. Load balance across multiple servers
6. Use CDN for static assets
