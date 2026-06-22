from flask import Flask, request
import boto3
import os
import time

app = Flask(__name__)

# Globalny bufor zajmujacy pamiec
memory_hog = []


@app.route("/")
def health():
    return {"status": "ok"}


@app.route("/whoami")
def whoami():
    sts = boto3.client("sts")
    identity = sts.get_caller_identity()
    return {
        "account": identity.get("Account"),
        "arn": identity.get("Arn"),
    }


@app.route("/s3")
def s3_list():
    bucket = request.args.get("bucket", "some-bucket-that-does-not-exist")
    s3 = boto3.client("s3")

    try:
        resp = s3.list_objects_v2(Bucket=bucket, MaxKeys=5)
        return {"bucket": bucket, "keys": [o["Key"] for o in resp.get("Contents", [])]}
    except Exception as e:
        return {"bucket": bucket, "error": str(e)}, 500


@app.route("/allocate")
def allocate():
    global memory_hog

    if not memory_hog:
        # ~1 GB RAM -- wystarczy zeby przekroczyc limit pamieci taska
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


@app.route("/cpu")
def cpu():
    end = time.time() + 60

    x = 0
    while time.time() < end:
        x += 1

    return {"x": x}


@app.route("/slow")
def slow():
    delay = int(request.args.get("seconds", 10))
    time.sleep(delay)
    return {"status": "ok", "slept": delay}


@app.route("/crash")
def crash():
    # Natychmiastowe, brzydkie zakonczenie procesu kontenera (symulacja crash loop)
    os._exit(1)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
