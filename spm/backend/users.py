# -*- coding: utf-8 -*-
from spm.backend.models import User, Project
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
        ukey = do_registration(verification_data["email"])
      else: # There <rage>BETTER BE</rage> only 1 users in this list. lawl. DD2. lawl.
        for user in users.run():
          ukey = user.key
          break

      verification_data["ukey"] = ukey
      return verification_data
    elif verification_data["status"] == "failure":
      return verification_data

def get_user_profile(key):
  user = User.get(key)
  projects = user.positions.keys()
  for i in xrange(len(projects)):
    project = Project.get(projects[i])
    projects[i] = {
      "key": projects[i],
      "name": project.name
    }

  user_json = {
    "name": user.name,
    "positions": user.positions,
    "projects": projects,
    "emails" : list(user.indexes("email_bin"))
  }

  return user_json

def change_name(key, name):
  user = User.get(key)
  user.name = name
  user.save()