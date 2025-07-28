import os
from flask import Flask, jsonify 
from config import Config 
import datetime

app = Flask(__name__)
app.config.from_object(Config) 

@app.route('/api/status', methods=['GET'])
def get_status():
    status_data = {
        "status": "online",
        "message": "API works fine!",
        "timestamp": datetime.datetime.now().isoformat(), 
        "version": "1.0.1"
    }
    app.logger.info("Status endpoint accessed. Returning JSON data.")
    return jsonify(status_data)

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)