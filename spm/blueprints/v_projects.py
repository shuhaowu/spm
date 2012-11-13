# -*- coding: utf-8 -*-
from flask import Blueprint, request, abort, jsonify, session
from settings import TEMPLATES_FOLDER, STATIC_FOLDER
blueprint = Blueprint("projects", __name__, template_folder=TEMPLATES_FOLDER,
    static_folder=STATIC_FOLDER)

from riakkit import NotFoundError

from spm.backend import projects
from spm.blueprints.helpers import login_required
from functools import wraps

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

def owner_required(f):
  @wraps(f)
  def df(project_key, *args, **kwargs):
    userkey = session.get("key", False)
    if userkey not in projects.get_project_json(project_key)["owners"]:
      return abort(403)
    return f(project_key=project_key, *args, **kwargs)
  return df

@blueprint.route("/todo/<project_key>", methods=["GET"])
@login_required
def get_todo_items(project_key):
  return jsonify(items=projects.get_todo_item_project(project_key))

@blueprint.route("/todo/<project_key>", methods=["POST"])
@login_required
def new_todo_item(project_key):
  todo = projects.create_todo_item(project_key, request.json)
  return jsonify({"key" : todo.key})

check_todo_owner = lambda project_key, todo_key: session["key"] in projects.get_project_json(project_key)["owners"] or session["key"] == projects.get_todo_json(todo_key)["author"]

@blueprint.route("/todo/<project_key>/<todo_key>", methods=["PUT"])
@login_required
def edit_todo_item(project_key, todo_key):
  if not request.json:
    return abort(400)

  try:
    if check_todo_owner(project_key, todo_key):
      projects.edit_todo_item(todo_key, request.json)
      return jsonify(status="ok")
  except NotFoundError:
    return abort(403)
  return abort(500)

@blueprint.route("/todo/<project_key>/<todo_key>", methods=["DELETE"])
@login_required
def delete_todo_item(project_key, todo_key):
  try:
    if check_todo_owner(project_key, todo_key):
      projects.delete_todo_item(todo_key)
      return jsonify(status="ok")
  except NotFoundError:
    return abort(403)
  return abort(500)

@blueprint.route("/todo/<project_key>/done/<todo_key>", methods=["POST"])
@login_required
def mark_todo_item_done(project_key, todo_key):
  if not request.json:
    return abort(400)

  try:
    if check_todo_owner(project_key, todo_key):
      projects.mark_todo_done(todo_key, request.json["done"])
      return jsonify(status="ok")
  except NotFoundError:
    return abort(404)

  return abort(500)
