import os

DEBUG = False
DEPLOY_PORT = 8106

APP_FOLDER = os.path.dirname(os.path.abspath(__file__))
STATIC_FOLDER = os.path.join(APP_FOLDER, "static")
TEMPLATES_FOLDER = os.path.join(APP_FOLDER, "templates")
SECRET_KEY = "nUbaRau1GjG1TqRKGDYAm4gpC7wiWGleXsc0iHZuFIb08rtAp/4n55KJidEhvVnci"
MAX_CONTENT_LENGTH = 20 * 1024 * 1024 # Capped to 20MB
SERVER_URL = "http://ardroid.thekks.net"