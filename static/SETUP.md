# Challenge Download Setup

## Overview

The platform now serves a static `challenges.zip` file from the `static/` directory when users click "Download All Challenges" on the Challenges page.

## How It Works

1. **Frontend**: The Challenges page has a download card with a link to `/api/download-challenges`
2. **Backend**: The `/api/download-challenges` endpoint serves the file at `static/challenges.zip`
3. **Users**: Click the download button and receive the ZIP file

## Setting Up Your Challenges

### Quick Method
1. Create your challenge files in a directory
2. ZIP them: `zip -r static/challenges.zip your_challenge_folder/`
3. Done! Users can now download them

### Example Structure
```
your_challenge_folder/
├── README.md (instructions)
├── challenge_1/
│   ├── README.md (challenge description)
│   └── files...
├── challenge_2/
│   └── files...
└── challenge_3/
    └── files...
```

## Sample Included

A sample `challenges.zip` is already included with basic challenge descriptions for the default 3 challenges.

## Notes

- The ZIP file path is: `static/challenges.zip`
- Replace this file with your own challenges
- File size limit: Keep it reasonable for downloads (< 100MB recommended)
- The file will be served with the name `ctf_challenges.zip` when downloaded
