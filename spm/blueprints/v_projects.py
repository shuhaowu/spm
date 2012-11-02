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
@login_required
def view_project(key):
  try:
    project = projects.get_project_json(key)
  except NotFoundError:
    return abort(404)
  project["status"] = "ok"
  return jsonify(project)


@blueprint.route("/wall/<key>", methods=["GET", "POST"])
@blueprint.route("/wall/<key>/<post_key>", methods=["DELETE"])
@login_required
def wall_post(key, post_key=None):
  if request.method == "GET":
    try:
      posts = projects.get_all_posts_from_project(key)
    except NotFoundError:
      return abort(404)
    return jsonify(status="ok", posts=posts)
  elif request.method == "POST":
    try:
      if session["key"] in projects.get_project_json(key)["owners"]:
        post = projects.add_wall_post(key, request.json["content"], session["key"])
        return jsonify(projects.wall_post_to_display_json(post))
      else:
        return abort(403)
    except NotFoundError:
      return abort(404)
  elif request.method == "DELETE":
    try:
      post = projects.get_wall_post(post_key)
    except NotFoundError:
      return abort(404)

    if post.getRawData("author") == session["key"]:
      post.delete()
      return jsonify(status="ok")
    else:
      return abort(403)
