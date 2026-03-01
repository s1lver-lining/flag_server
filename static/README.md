# CTF Challenges

Place your `challenges.zip` file in this directory.

This ZIP file will be served when users click "Download All Challenges" on the platform.

## Creating Your Challenges ZIP

1. Create a directory with all your challenge files
2. Organize them however you like (by category, difficulty, etc.)
3. Zip the directory: `zip -r challenges.zip your_challenge_folder/`
4. Place `challenges.zip` in this `static/` directory

The file will be available at: `http://localhost:5000/api/download-challenges`
