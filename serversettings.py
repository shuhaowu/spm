import os

DEBUG = False
DEPLOY_PORT = 8106

APP_FOLDER = os.path.dirname(os.path.abspath(__file__))
STATIC_FOLDER = os.path.join(APP_FOLDER, "static")
TEMPLATES_FOLDER = os.path.join(APP_FOLDER, "templates")
SECRET_KEY = "iOlgiqT44M7Xkg5VBX9YnGMZUef5zUrPGNrmco8HFTQ="
MAX_CONTENT_LENGTH = 20 * 1024 * 1024 # Capped to 20MB