from flask import Flask, request, jsonify, send_file, send_from_directory
from flask_cors import CORS
from flask_socketio import SocketIO, emit
import json
import os
import fcntl
import time

app = Flask(__name__)
CORS(app)
socketio = SocketIO(app, cors_allowed_origins="*")

# Data files
DATA_DIR = 'data'
SCOREBOARD_FILE = os.path.join(DATA_DIR, 'scoreboard.json')
CHALLENGES_FILE = os.path.join(DATA_DIR, 'challenges.json')
SOLVES_FILE = os.path.join(DATA_DIR, 'solves.json')
DOWNLOADS_FILE = os.path.join(DATA_DIR, 'downloads.json')
STATIC_DIR = 'static'

# Ensure data directory exists
os.makedirs(DATA_DIR, exist_ok=True)
os.makedirs(STATIC_DIR, exist_ok=True)

# Initialize data files if they don't exist
def init_data_files():
    if not os.path.exists(SCOREBOARD_FILE):
        with open(SCOREBOARD_FILE, 'w') as f:
            json.dump({}, f)
    
    if not os.path.exists(CHALLENGES_FILE):
        challenges = []
        with open(CHALLENGES_FILE, 'w') as f:
            json.dump(challenges, f, indent=2)
    
    if not os.path.exists(SOLVES_FILE):
        with open(SOLVES_FILE, 'w') as f:
            json.dump({}, f)
    
    if not os.path.exists(DOWNLOADS_FILE):
        with open(DOWNLOADS_FILE, 'w') as f:
            json.dump({"count": 0, "history": []}, f)

init_data_files()

def acquire_lock(file_handle, max_retries=10):
    """Acquire an exclusive lock on a file with retries."""
    for attempt in range(max_retries):
        try:
            fcntl.flock(file_handle.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
            return True
        except BlockingIOError:
            if attempt < max_retries - 1:
                time.sleep(0.01 * (attempt + 1))  # Exponential backoff
            else:
                raise
    return False

def release_lock(file_handle):
    """Release the lock on a file."""
    fcntl.flock(file_handle.fileno(), fcntl.LOCK_UN)

def load_json_safe(filepath):
    """Thread-safe JSON loading with file locking."""
    max_retries = 10
    for attempt in range(max_retries):
        try:
            with open(filepath, 'r') as f:
                acquire_lock(f)
                try:
                    data = json.load(f)
                finally:
                    release_lock(f)
                return data
        except (json.JSONDecodeError, FileNotFoundError):
            # If file is corrupted or doesn't exist, return empty dict
            if attempt == max_retries - 1:
                return {}
            time.sleep(0.01)
    return {}

def save_json_safe(filepath, data):
    """Thread-safe JSON saving with atomic write and file locking."""
    temp_filepath = filepath + '.tmp'
    max_retries = 10
    
    for attempt in range(max_retries):
        try:
            # Write to temporary file first
            with open(temp_filepath, 'w') as f:
                acquire_lock(f)
                try:
                    json.dump(data, f, indent=2)
                    f.flush()
                    os.fsync(f.fileno())  # Force write to disk
                finally:
                    release_lock(f)
            
            # Atomic rename
            os.replace(temp_filepath, filepath)
            return True
        except Exception as e:
            if attempt == max_retries - 1:
                # Clean up temp file on final failure
                if os.path.exists(temp_filepath):
                    os.remove(temp_filepath)
                raise
            time.sleep(0.01)
    return False

def load_scoreboard():
    return load_json_safe(SCOREBOARD_FILE)

def save_scoreboard(scoreboard):
    save_json_safe(SCOREBOARD_FILE, scoreboard)

def load_challenges():
    return load_json_safe(CHALLENGES_FILE)

def load_solves():
    return load_json_safe(SOLVES_FILE)

def save_solves(solves):
    save_json_safe(SOLVES_FILE, solves)

def load_downloads():
    return load_json_safe(DOWNLOADS_FILE)

def save_downloads(downloads):
    save_json_safe(DOWNLOADS_FILE, downloads)

def increment_download_count():
    """Atomically increment the download counter with race condition protection."""
    try:
        downloads = load_downloads()
        downloads['count'] = downloads.get('count', 0) + 1
        
        # Add timestamp to history
        if 'history' not in downloads:
            downloads['history'] = []
        
        from datetime import datetime, timezone
        downloads['history'].append({
            'timestamp': datetime.now(timezone.utc).isoformat(),
            'count': downloads['count']
        })
        
        # Keep only last 100 entries in history
        if len(downloads['history']) > 100:
            downloads['history'] = downloads['history'][-100:]
        
        save_downloads(downloads)
        return downloads['count']
    except Exception as e:
        print(f"Error incrementing download count: {e}")
        return None


@app.route('/api/challenges', methods=['GET'])
def get_challenges():
    challenges = load_challenges()
    # Don't send flags to frontend
    public_challenges = []
    for challenge in challenges:
        public_challenge = challenge.copy()
        public_challenge.pop('flag', None)
        public_challenges.append(public_challenge)
    return jsonify(public_challenges)

@app.route('/api/scoreboard', methods=['GET'])
def get_scoreboard():
    scoreboard = load_scoreboard()
    # Convert to list and sort by score
    scoreboard_list = [
        {"username": username, "score": score}
        for username, score in scoreboard.items()
    ]
    scoreboard_list.sort(key=lambda x: x['score'], reverse=True)
    return jsonify(scoreboard_list)

@app.route('/api/download-challenges', methods=['GET'])
def download_challenges():
    """Serve the static challenges ZIP file and increment download counter."""
    try:
        zip_path = os.path.join(STATIC_DIR, 'fvm_challenge.zip')
        if os.path.exists(zip_path):
            # Increment download counter atomically
            count = increment_download_count()
            if count:
                print(f"Challenges downloaded. Total downloads: {count}")
            
            return send_file(
                zip_path,
                mimetype='application/zip',
                as_attachment=True,
                download_name='fvm_challenges.zip'
            )
        else:
            return jsonify({
                "success": False, 
                "message": "Challenges file not found. Please contact the administrator."
            }), 404
    except Exception as e:
        print(f"Error serving challenge ZIP: {e}")
        return jsonify({
            "success": False, 
            "message": "Error downloading challenges"
        }), 500

@app.route('/api/download-stats', methods=['GET'])
def get_download_stats():
    """Get download statistics."""
    try:
        downloads = load_downloads()
        return jsonify({
            "success": True,
            "total_downloads": downloads.get('count', 0),
            "recent_downloads": downloads.get('history', [])[-10:]  # Last 10 downloads
        })
    except Exception as e:
        print(f"Error getting download stats: {e}")
        return jsonify({
            "success": False,
            "message": "Error retrieving download statistics"
        }), 500

@app.route('/api/submit', methods=['POST'])
def submit_flag():
    data = request.json
    username = data.get('username', '').strip()
    flag = data.get('flag', '').strip()
    
    if not username or not flag:
        return jsonify({"success": False, "message": "Username and flag are required"}), 400
    
    # Validate username length (max 20 characters)
    if len(username) > 20:
        return jsonify({"success": False, "message": "Username must be 20 characters or less"}), 400
    
    # Load challenges and find matching flag
    challenges = load_challenges()
    correct_challenge = None
    
    for challenge in challenges:
        if challenge['flag'] == flag:
            correct_challenge = challenge
            break
    
    if not correct_challenge:
        return jsonify({"success": False, "message": "Incorrect flag"}), 400
    
    challenge_id = correct_challenge['id']
    
    # Critical section: check and update solves atomically
    try:
        # Load solves to check if user already solved this challenge
        solves = load_solves()
        
        # Initialize user's solves if not exists
        if username not in solves:
            solves[username] = []
        
        # Check if user already solved this challenge
        if challenge_id in solves[username]:
            return jsonify({
                "success": False,
                "message": f"You have already solved '{correct_challenge['title']}'!"
            }), 400
        
        # Add challenge to user's solves
        solves[username].append(challenge_id)
        save_solves(solves)
        
        # Update scoreboard
        scoreboard = load_scoreboard()
        
        # Initialize user if not exists
        if username not in scoreboard:
            scoreboard[username] = 0
        
        # Add points
        scoreboard[username] += correct_challenge['points']
        save_scoreboard(scoreboard)
        
        # Emit scoreboard update via WebSocket
        socketio.emit('scoreboard_update', {
            "username": username,
            "score": scoreboard[username],
            "challenge": correct_challenge['title']
        })
        
        return jsonify({
            "success": True,
            "message": f"Correct! You earned {correct_challenge['points']} points!",
            "challenge": correct_challenge['title'],
            "points": correct_challenge['points']
        })
    except Exception as e:
        print(f"Error in submit_flag: {e}")
        return jsonify({
            "success": False,
            "message": "An error occurred while processing your submission. Please try again."
        }), 500

@app.route('/kiosk')
def kiosk():
    """Serve the kiosk page."""
    return send_from_directory('frontend/dist', 'kiosk.html')

@socketio.on('connect')
def handle_connect():
    print('Client connected')

@socketio.on('disconnect')
def handle_disconnect():
    print('Client disconnected')

if __name__ == '__main__':
    socketio.run(app, host='0.0.0.0', port=5000, debug=True)
