# -*- coding: utf-8 -*-
from spm.backend.models import Project, Content, TodoItem, Schedule
from datetime import datetime

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

def create_todo_item(project_key, json):
  duedate = json.get("duedate", None)
  if duedate:
    duedate = datetime.strptime(duedate, "%m/%d/%Y")

  ti = TodoItem(title=json["title"], desc=json.get("desc", ""), duedate=duedate)
  ti.addIndex("project_bin", project_key)

  assignee = json.get("assignee")
  if assignee:
    ti.addIndex("assigned_to_bin", assignee)

  category = json.get("categories")
  if category:
    ti.addIndex("category_bin", category)
  ti.save()
  return ti

def todo_to_json_simple(todo):
  return {"key" : todo.key, "title" : todo.title}

def todo_to_json(todo):
  todo_json = todo.serialize()

  todo_json["assignee"] = list(todo.index("assigned_to", []))
  todo_json["project"] = todo.index("project_bin").pop()
  todo_json["categories"] = list(todo.index("category_bin", []))
  todo_json["key"] = todo.key

  if "desc" in todo_json and todo_json["desc"]:
    todo_json["desc"] = dict(todo_json["desc"])

  return todo_json

def get_todo_json(todo_key):
  return todo_to_json(TodoItem.get(todo_key))

def get_todo_item_with_2i(field, value, simple=False):
  items_queries = TodoItem.indexLookup(field, value)
  items = []
  for item in items_queries.run():
    if simple:
      items.append(todo_to_json_simple(item))
    else:
      items.append(todo_to_json(item))

  items.sort(key=lambda x: x["pubdate"])
  return items

def get_todo_item_project(project):
  return get_todo_item_with_2i("project_bin", project)

def get_todo_item_person(user):
  return get_todo_item_with_2i("assigned_to_bin", user)

def get_todo_item_project_simple(project):
  return get_todo_item_with_2i("project_bin", project, True)

def delete_todo_item(todo_key):
  TodoItem.get(todo_key).delete()

def edit_todo_item(todo_key, json):
  todo = TodoItem.get(todo_key)
  if json.get("title"):
    todo.title = json["title"]

  if json.get("desc"):
    todo.desc = json["desc"]

  if json.get("duedate"):
    todo.duedate = datetime.strptime(json["duedate"], "%m/%d/%Y")

  if json["categories"]:
    todo.removeIndex("category_bin", silent=True)
    todo.addIndex("category_bin", json["categories"][0])

  todo.save()
  return todo

def mark_todo_done(todo_key, done):
  todo = TodoItem.get(todo_key)
  todo.done = done
  todo.save()

def schedule_to_json(schedule):
  json = schedule.serialize()
  json["key"] = schedule.key
  json["project"] = list(schedule.indexes("project_bin"))[0]
  return json

def get_schedules(project_key):
  schedules_queries = Schedule.indexLookup("project_bin", project_key)
  schedules = []
  for schedule in schedules_queries.run():
    schedules.append(schedule_to_json(schedule))

  schedules.sort(key=lambda x: x["starttime"])
  return schedules

def create_schedule_item(project_key, json):
  json.pop("key", None)
  json["starttime"] = datetime.strptime(json["starttime"], "%m/%d/%Y %H:%M")
  json["endtime"] = datetime.strptime(json["endtime"], "%m/%d/%Y %H:%M")
  schedule = Schedule(**json)
  schedule.addIndex("project_bin", project_key)
  schedule.save()
  return schedule

def delete_schedule(schedule_key):
  Schedule.get(schedule_key).delete()