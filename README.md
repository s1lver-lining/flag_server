# CTF Flag Submission Platform

A modern CTF (Capture The Flag) challenge platform with real-time scoreboard updates.

## Features

- 🚩 Challenge browsing and management
- 📥 Challenge download with tracking
- ✅ Flag submission system
- 🏆 Live scoreboard with real-time updates (WebSocket)
- 💯 Automatic score calculation
- 🔒 Thread-safe operations (no race conditions)
- 🎨 Modern UI with Tailwind CSS
- ⚡ Fast and responsive Svelte frontend
- 🔌 Flask backend with Socket.IO for real-time updates
- 📊 Download statistics tracking

## Tech Stack

### Backend
- Flask (Python web framework)
- Flask-CORS (Cross-origin resource sharing)
- Flask-SocketIO (WebSocket support)
- JSON-based data storage

### Frontend
- Svelte (Reactive UI framework)
- Tailwind CSS (Styling)
- Socket.IO Client (Real-time updates)
- Vite (Build tool)

## Installation

### Prerequisites
- Python 3.8+
- Node.js 16+
- npm

### Backend Setup

1. Install Python dependencies:
```bash
pip install -r requirements.txt
```

2. Run the Flask server:
```bash
python app.py
```

The backend will start on `http://localhost:5000`

### Frontend Setup

1. Navigate to the frontend directory:
```bash
cd frontend
```

2. Install dependencies:
```bash
npm install
```

3. Run the development server:
```bash
npm run dev
```

The frontend will start on `http://localhost:3000`

## Usage

1. Start the backend server first (it must be running on port 5000)
2. Start the frontend development server
3. Open your browser to `http://localhost:3000`

### Using the Platform

1. **View Challenges**: Browse available CTF challenges on the Challenges tab
2. **Download Challenges**: Click the download button to get all challenge files as a ZIP
3. **Submit Flags**: Go to the Submit Flag tab, enter your username and flag
4. **View Scoreboard**: Check the live scoreboard to see rankings

### Setting Up Challenge Files

Place your `challenges.zip` file in the `static/` directory. This file will be served when users click "Download All Challenges".

To create your challenges ZIP:
```bash
# Create a directory with your challenge files
mkdir my_challenges
# ... add your challenge files ...
# Create the ZIP
zip -r static/challenges.zip my_challenges/
```

A sample `challenges.zip` is included by default.

### Monitoring Download Statistics

Check how many times challenges have been downloaded:

```bash
# Via API
curl http://localhost:5000/api/download-stats

# Or check the file directly
cat data/downloads.json
```

See [DOWNLOAD_STATS.md](DOWNLOAD_STATS.md) for more details.

### Adding Custom Challenges

Edit `data/challenges.json` to add your own challenges:

```json
{
  "id": 4,
  "title": "Your Challenge Name",
  "description": "Challenge description",
  "category": "Web",
  "points": 200,
  "flag": "FLAG{your_flag_here}"
}
```

## Project Structure

```
fvm_ctf/
├── app.py                 # Flask backend
├── requirements.txt       # Python dependencies
├── data/                  # Data storage
│   ├── challenges.json    # Challenge definitions
│   └── scoreboard.json    # User scores
└── frontend/
    ├── src/
    │   ├── App.svelte           # Main app component
    │   ├── components/
    │   │   ├── Challenges.svelte     # Challenge list
    │   │   ├── FlagSubmission.svelte # Flag submission form
    │   │   └── Scoreboard.svelte     # Live scoreboard
    │   ├── main.js
    │   └── app.css
    ├── index.html
    ├── package.json
    ├── vite.config.js
    └── tailwind.config.js
```

## API Endpoints

- `GET /api/challenges` - Get all challenges (without flags)
- `GET /api/scoreboard` - Get current scoreboard
- `POST /api/submit` - Submit a flag
  ```json
  {
    "username": "player1",
    "flag": "FLAG{...}"
  }
  ```

## WebSocket Events

- `scoreboard_update` - Emitted when a user successfully submits a flag
  ```json
  {
    "username": "player1",
    "score": 250,
    "challenge": "Challenge Name"
  }
  ```

## Building for Production

### Quick Start (Recommended)

The easiest way to run in production:

```bash
./run.sh
```

This will:
- Install dependencies
- Build the frontend
- Start backend with Gunicorn (production WSGI server)
- Start frontend server
- Both services shut down gracefully when you press Ctrl+C

**Configure ports and workers:**
```bash
BACKEND_PORT=8000 FRONTEND_PORT=8080 WORKERS=8 ./run.sh
```

See [PRODUCTION.md](PRODUCTION.md) for advanced deployment options including:
- Systemd service setup
- Nginx reverse proxy configuration
- Docker deployment
- SSL/HTTPS setup
- Monitoring and logging

### Manual Build

Frontend:
```bash
cd frontend
npm run build
```

The built files will be in `frontend/dist/`

### Backend
For production, use a WSGI server like Gunicorn:
```bash
pip install gunicorn eventlet
gunicorn --worker-class eventlet -w 1 --bind 0.0.0.0:5000 app:app
```

## License

MIT License - Feel free to use this for your CTF events!
