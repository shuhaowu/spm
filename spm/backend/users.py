# -*- coding: utf-8 -*-
from spm.backend.models import User, TodoItem, Project
import requests
import json
from datetime import datetime
from settings import SERVER_URL

def _add_to_projects(email, u, t):
  projects_query = Project.indexLookup("unregistered_bin", email + " " + t)
  for project in projects_query.run():
    project.addIndex(t + "_bin", u.key)
    project.removeIndex("unregistered_bin", email + " " + t)
    project.save()

def add_to_projects(email, u):
  _add_to_projects(email, u, "owners")
  _add_to_projects(email, u, "participants")

def do_registration(email):
  u = User()
  u.addIndex("email_bin", email)
  u.save()
  add_to_projects(email, u)
  return u.key

def do_login(assertion):
  data = {"assertion" : assertion, "audience" : SERVER_URL}
  resp = requests.post("https://verifier.login.persona.org/verify", data=data, verify=True)

  if resp.status_code == 200:
    verification_data = json.loads(resp.content)

    if verification_data["status"] == "okay":

      users = User.indexLookup("email_bin", verification_data["email"])
      if len(users) == 0:
        key = do_registration(verification_data["email"])
      else: # There <rage>BETTER BE</rage> only 1 users in this list. lawl. DD2. lawl.
        for user in users.run():
          key = user.key
          break

      verification_data["key"] = key
      return verification_data
    elif verification_data["status"] == "failure":
      return verification_data

def get_user_simple(key):
  user = User.get(key)
  user_json = {
    "key" : key,
    "name" : user.name,
    "positions" : user.positions,
    "emails" : list(user.indexes("email_bin"))
  }
  return user_json

def get_user_projects_with_simple(user):
  project_query = Project.indexLookup("owners_bin", user.key)
  projects = project_query.all()
  project_query = Project.indexLookup("participants_bin", user.key)
  projects.extend(project_query.all())

  for i in xrange(len(projects)):
    projects[i] = {"key" : projects[i].key, "name" : projects[i].name}
  return projects

def get_user_profile(key):
  user = User.get(key)

  user_json = {
    "key" : user.key,
    "name": user.name,
    "positions": user.positions,
    "projects": get_user_projects_with_simple(user),
    "emails" : list(user.indexes("email_bin"))
  }

  return user_json

def change_name(key, name):
  user = User.get(key)
  user.name = name
  user.save()

def get_personalized_data(key):
  user = User.get(key)

  todo_query = TodoItem.indexLookup("assigned_to_bin", key)
  todos = []
  now = datetime.now()
  for todo in todo_query.run():
    print todo.done
    if not todo.done:
      t = {"title" : todo.title, "desc" : todo.desc["html"]}
      if todo.duedate:
        t["time_remaining"] = (todo.duedate - now).total_seconds()
      else:
        t["time_remaining"] = None

      todos.append(t)

  todos.sort(key=lambda x: x["time_remaining"])

  user_json = {
    "projects" : get_user_projects_with_simple(user),
    "todos" : todos,
    "name" : user.name
  }

  return user_json