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

def participant_required(f):
  @wraps(f)
  def df(project_key, *args, **kwargs):
    userkey = session.get("key", False)
    project_json = projects.get_project_json(project_key)
    if userkey in project_json["owners"] or userkey in project_json["participants"]:
      return f(project_key=project_key, *args, **kwargs)
    return abort(403)

  return df

def owner_required(f):
  @wraps(f)
  def df(project_key, *args, **kwargs):
    userkey = session.get("key", False)
    if userkey not in projects.get_project_json(project_key)["owners"]:
      return abort(403)
    return f(project_key=project_key, *args, **kwargs)
  return df

@blueprint.route("/new", methods=["POST"])
@login_required
def new_project():
  project = projects.new_project(request.form["name"], session["key"])
  return jsonify(status="ok", key=project.key)

@blueprint.route("/view/<project_key>")
@participant_required
def view_project(project_key):
  try:
    project = projects.get_project_json(project_key)
  except NotFoundError:
    return abort(404)
  project["status"] = "ok"
  return jsonify(project)


@blueprint.route("/wall/<project_key>", methods=["GET", "POST"])
@blueprint.route("/wall/<project_key>/<post_key>", methods=["DELETE"])
@participant_required
def wall_post(project_key, post_key=None):
  if request.method == "GET":
    try:
      posts = projects.get_all_posts_from_project(project_key)
    except NotFoundError:
      return abort(404)
    return jsonify(status="ok", posts=posts)
  elif request.method == "POST":
    try:
      if session["key"] in projects.get_project_json(project_key)["owners"]:
        post = projects.add_wall_post(project_key, request.json["content"], session["key"])
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

@blueprint.route("/todo/<project_key>", methods=["GET"])
@participant_required
def get_todo_items(project_key):
  return jsonify(items=projects.get_todo_item_project(project_key))

@blueprint.route("/todo/<project_key>", methods=["POST"])
@participant_required
def new_todo_item(project_key):
  json = request.json
  if not json or not json["title"]:
    return abort(400)

  todo = projects.create_todo_item(project_key, request.json, session["key"])
  return jsonify({"key" : todo.key})

check_todo_owner = lambda project_key, todo_key: session["key"] in projects.get_project_json(project_key)["owners"] or session["key"] == projects.get_todo_json(todo_key)["author"]

@blueprint.route("/todo/<project_key>/<todo_key>", methods=["PUT"])
@participant_required
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
@participant_required
def delete_todo_item(project_key, todo_key):
  try:
    if check_todo_owner(project_key, todo_key):
      projects.delete_todo_item(todo_key)
      return jsonify(status="ok")
  except NotFoundError:
    return abort(403)
  return abort(500)

@blueprint.route("/todo/<project_key>/done/<todo_key>", methods=["POST"])
@participant_required
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

@blueprint.route("/schedule/<project_key>", methods=["GET"])
@participant_required
def get_schedules(project_key):
  return jsonify(items=projects.get_schedules(project_key))

@blueprint.route("/schedule/<project_key>", methods=["POST"])
@owner_required
def new_schedule(project_key):
  json = request.json
  if not json or not json["title"] or not json["location"] or not json["starttime"] or not json["endtime"]:
    return abort(400)

  schedule = projects.create_schedule_item(project_key, json)
  return jsonify(key=schedule.key)

@blueprint.route("/schedule/<project_key>/<schedule_key>", methods=["DELETE"])
@owner_required
def delete_schedule(project_key, schedule_key):
  try:
    projects.delete_schedule(schedule_key)
  except NotFoundError:
    return abort(404)
  return jsonify(status="ok")

@blueprint.route("/members/<project_key>", methods=["GET"])
@participant_required
def get_members_list(project_key):
  try:
    members_list = projects.get_members_list(project_key)
    return jsonify(items=members_list)
  except NotFoundError:
    return abort(404)
  return abort(500)

@blueprint.route("/manage/<project_key>/get_emails", methods=["GET"])
@owner_required
def get_member_emails(project_key):
  try:
    return jsonify(**projects.get_member_emails(project_key))
  except NotFoundError:
    return abort(404)
  return abort(500)

@blueprint.route("/manage/<project_key>/set_owners_emails", methods=["POST"])
@owner_required
def set_owners_emails(project_key):
  if not request.json or not request.json.get("emails"):
    return abort(400)

  try:
    if not projects.set_owners(project_key, request.json["emails"]):
      return abort(400)
    return jsonify(status="ok")
  except NotFoundError:
    return abort(404)
  return abort(500)

@blueprint.route("/manage/<project_key>/set_participants_emails", methods=["POST"])
@owner_required
def set_participants_emails(project_key):
  if not request.json or not request.json.get("emails"):
    return abort(400)

  try:
    if not projects.set_participants(project_key, request.json["emails"]):
      return abort(400)
    return jsonify(status="ok")
  except NotFoundError:
    return abort(404)
  return abort(500)