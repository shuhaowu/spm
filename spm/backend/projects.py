# -*- coding: utf-8 -*-
from spm.backend.models import Project, Content, TodoItem

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

def wall_post_to_display_json(post):
  return {
    "key": post.key,
    "content": post.title,
    "author": {"key" : post.author.key, "name": post.author.name, "emails": list(post.author.index("email_bin"))},
    "pubdate": post.date.isoformat()
  }

def get_all_posts_from_project(key):
  post_queries = Content.indexLookup("project_bin", key, bucket="spm_wallposts")
  posts = []
  for post in post_queries.run():
    posts.append(wall_post_to_display_json(post))
  return sorted(posts, key=lambda x: x["pubdate"])[:50] # TODO: pagination? lol? delete old items? wut

def get_wall_post(key):
  return Content.get(key, bucket="spm_wallposts")


def create_todo_item(name, desc, duedate, project, assigned_to="noone", category="default"):
  ti = TodoItem(name=name, desc=desc, duedate=duedate)
  ti.addIndex("assigned_to_bin", assigned_to)
  ti.addIndex("project_bin", project)
  ti.addIndex("category_bin", category)
  ti.save()
  return ti

def todo_to_json(todo):
  todo_json = todo.deserialize()
  todo_json["assigned_to"] = list(todo_json.index("assigned_to", []))
  todo_json["project"] = todo_json.index("project_bin").pop()
  todo_json["category"] = todo_json.index("category_bin")

def get_todo_item_with_2i(field, value):
  items_queries = TodoItem.indexLookup(field, value)
  items = []
  for item in items_queries.run():
    items.append(todo_to_json(item))
  return items

def get_todo_item_person(user):
  return get_todo_item_with_2i("assigned_to_bin")

def get_todo_item_project(project):
  return get_todo_item_with_2i("project_bin")

def mark_todo_down(todo_key):
  todo = TodoItem.get(todo_key)
  todo.done = True
  todo.save()