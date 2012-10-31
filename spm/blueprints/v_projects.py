# -*- coding: utf-8 -*-
from flask import Blueprint, request, abort, jsonify, session
from settings import TEMPLATES_FOLDER, STATIC_FOLDER
blueprint = Blueprint("projects", __name__, template_folder=TEMPLATES_FOLDER,
    static_folder=STATIC_FOLDER)

from riakkit import NotFoundError

from spm.backend import projects
from spm.blueprints.helpers import login_required

meta = {
    "url_prefix" : "/projects",
}

@blueprint.route("/new", methods=["POST"])
@login_required
def new_project():
  project = projects.new_project(request.form["name"], session["key"])
  return jsonify(status="ok", key=project.key)

@blueprint.route("/view/<key>")
def view_project(key):
  try:
    project = projects.get_project_json(key)
  except NotFoundError:
    return abort(404)
  project["status"] = "ok"
  return jsonify(project)