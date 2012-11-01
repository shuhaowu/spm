# -*- coding: utf-8 -*-
from spm.backend.models import Project, Content

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
    "participants": list(project.index("partipants_bin", [])),
  }
  return project_json

def get_project_json_simple(key):
  project = Project.get(key)
  return {"key" : project.key, "name" : project.name}

def add_wall_post(key, content, user):
  post = Content(title=content, author=user)
  post.addIndex("project_bin", key)
  post.save(bucket="spm_wallposts")
  return post

def get_all_posts_from_project(key):
  post_queries = Content.indexLookup("project_bin", key, bucket="spm_wallposts")
  posts = []
  for post in post_queries.run():
    posts.append({"key": post.key, "content": post.title, "author": post.author.name, "pubdate": post.date.isoformat()})
  return sorted(posts, key=lambda x: x["pubdate"])[:50] # TODO: pagination? lol? delete old items? wut

def get_wall_post(key):
  return Content.get(key, bucket="spm_wallposts")
