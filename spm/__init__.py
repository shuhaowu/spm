from flask import Flask, session
from spm.blueprints import blueprints
from settings import *

app = Flask(__name__, static_folder=STATIC_FOLDER,
            template_folder=TEMPLATES_FOLDER)
app.secret_key = SECRET_KEY
app.config["MAX_CONTENT_LENGTH"] = MAX_CONTENT_LENGTH

@app.before_request
def before_request():
  app.jinja_env.globals["current_user_key"] = session.get("key", None)
  app.jinja_env.globals["current_user_email"] = session.get("email", None)

for blueprint, meta in blueprints:
  app.register_blueprint(blueprint, **meta)