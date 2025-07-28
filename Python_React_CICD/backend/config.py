import os

class Config:
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'strong_default_secret_key'