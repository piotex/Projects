# Project Setup Guide

Below are the steps to install and run the application.
Please ensure you have **Python 3.12** installed on your system.

---

## 1. Virtual Environment Setup

Install and activate a virtual environment to isolate the project dependencies from your system's global packages.

```bash
sudo apt install python3.12-venv -y
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

## 2. Run the Backend Server

Open a new terminal and run the backend script. This server provides the time data.

```bash
python3 backend.py
```

The server will be available at http://127.0.0.1:9999/.

## 3. Run the Frontend Server

Open a new terminal and launch the frontend server to host the index.html file.

```bash
source venv/bin/activate
python3 -m http.server 8000
```

The frontend will be available in your browser at http://127.0.0.1:8000/. You should see the clock application in action.
