# -*- coding: utf-8 -*-
from spm.backend.models import User, TodoItem, Project
import requests
import json

def do_registration(email):
  u = User()
  u.addIndex("email_bin", email)
  u.save()
  return u.key

def do_login(assertion):
  data = {"assertion" : assertion, "audience" : "http://localhost:4131"}
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
  for todo in todo_query.run():
    todos.append(todos.deserialize())

  todos.sort(key=lambda x: x["duedate"])

  user_json = {
    "projects" : get_user_projects_with_simple(user),
    "todos" : todos,
  }

  return user_json