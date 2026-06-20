from flask import Flask
import os
import tempfile
import random
import time

app = Flask(__name__)

# Globalny bufor zajmujący pamięć
memory_hog = []


@app.route("/")
def health():
    return {"status": "ok"}


@app.route("/allocate")
def allocate():
    global memory_hog

    if not memory_hog:
        # ~1 GB RAM
        memory_hog = [bytearray(100 * 1024 * 1024) for _ in range(10)]

    return {
        "status": "allocated",
        "chunks": len(memory_hog)
    }


@app.route("/free")
def free():
    global memory_hog

    memory_hog.clear()

    return {"status": "freed"}


@app.route("/report")
def report():
    start = time.time()

    filename = create_temp_file()

    try:
        numbers = load_numbers(filename)
        primes = expensive_operation(numbers)

        return {
            "primes_found": primes,
            "duration_sec": round(time.time() - start, 2)
        }

    finally:
        os.remove(filename)


def create_temp_file():
    fd, filename = tempfile.mkstemp(prefix="report_", suffix=".txt")

    with os.fdopen(fd, "w") as f:
        for _ in range(5_000_000):
            f.write(f"{random.randint(1, 100000)}\n")

    return filename

@app.route("/cpu")
def cpu():
    end = time.time() + 60

    x = 0
    while time.time() < end:
        x += 1

    return {"x": x}

    
def load_numbers(filename):
    with open(filename) as f:
        return [int(line.strip()) for line in f]


def is_prime(n):
    if n < 2:
        return False

    for i in range(2, int(n ** 0.5) + 1):
        if n % i == 0:
            return False

    return True


def expensive_operation(numbers):
    count = 0

    for n in numbers:
        if is_prime(n):
            count += 1

    return count


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)