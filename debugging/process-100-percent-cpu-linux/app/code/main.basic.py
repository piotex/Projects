from flask import Flask
import threading
import time

app = Flask(__name__)

@app.route("/")
def health():
    return {"status": "ok"}

@app.route("/report")
def report():
    return generate_report()

def generate_report():
    return str(expensive_operation())

def is_prime(n):
    for i in range(2, n):
        if n % i == 0:
            return False
    return True

def expensive_operation():
    count = 0
    for x in range(100_000_000):
        if is_prime(x):
            count += 1

    return count

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)