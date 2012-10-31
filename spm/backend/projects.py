# -*- coding: utf-8 -*-
from spm.backend.models import Project

def new_project(name, userkey):
  project = Project(name=name)
  project.addIndex("owners_bin", userkey)
  project.save()
  return project

def get_project_json(key):
  project = Project.get(key)
  project_json = {
    "key": project.key,
    "name": project.name,
    "desc": project.desc,
    "owners": list(project.index("owners_bin", [])),
    "participants": list(project.index("partipants_bin", []))
  }
  return project_json

def get_project_json_simple(key):
  project = Project.get(key)
  return {"key" : project.key, "name" : project.name}