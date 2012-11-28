# -*- coding: utf-8 -*-
from spm.backend.models import Project, Content, TodoItem, Schedule, User
from datetime import datetime

from riakkit import NotFoundError

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
    "participants": list(project.index("participants_bin", [])),
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


def get_author_json(author):
  a = {"key" : author.key, "emails" : list(author.index("email_bin"))}
  if not author.name:
    a["name"] = a["emails"]
  else:
    a["name"] = author.name
  return a

def wall_post_to_display_json(post):
  return {
    "key": post.key,
    "content": post.title,
    "author": get_author_json(post.author),
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

def create_todo_item(project_key, json, author):
  duedate = json.get("duedate", None)
  if duedate:
    duedate = datetime.strptime(duedate, "%m/%d/%Y")

  ti = TodoItem(title=json["title"], desc=json.get("desc", ""), duedate=duedate, author=author)
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

  assignees = todo.index("assigned_to_bin", [])
  if assignees:
    todo_json["assignee"] = assignees.pop()
  else:
    todo_json["assignee"] = None

  todo_json["project"] = todo.index("project_bin").pop()
  todo_json["categories"] = list(todo.index("category_bin", []))
  todo_json["key"] = todo.key
  todo_json["author"] = get_author_json(todo.author)

  if "desc" in todo_json and todo_json["desc"]:
    todo_json["desc"] = dict(todo_json["desc"])

  return todo_json

def get_todo_json(todo_key):
  return todo_to_json(TodoItem.get(todo_key))

def get_todo_item_with_2i(field, value, simple=False):
  items_queries = TodoItem.indexLookup(field, value)
  items = [] # could probably simplify with an integer counter on where each sections are and insert.
  done_items = []
  no_duedate = []
  list_to_append_to = items
  for item in items_queries.run():
    if item.done:
      list_to_append_to = done_items
    elif not item.duedate:
      list_to_append_to = no_duedate
    else:
      list_to_append_to = items

    if simple:
      list_to_append_to.append(todo_to_json_simple(item))
    else:
      list_to_append_to.append(todo_to_json(item))

  items.sort(key=lambda x: x["duedate"])
  done_items.sort(key=lambda x:["duedate"])
  items = items + no_duedate + done_items
  items.reverse()
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

  if json["assignee"] and json["assignee"] != "noone":
    todo.removeIndex("assigned_to_bin", silent=True)
    todo.addIndex("assigned_to_bin", json["assignee"])

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


def get_member_emails(project_key):
  project = Project.get(project_key)
  participants = project.indexes("participants_bin", [])
  owners = project.indexes("owners_bin", [])
  unregistered = project.indexes("unregistered_bin", [])
  participants_email = []
  owners_email = []
  unregistered_emails = []
  for owner_key in owners:
    try:
      owners_email.append(list(User.get(owner_key).index("email_bin", []))[0])
    except NotFoundError:
      raise Exception("User '%s' does not exist!" % owner_key)

  for participants_key in participants:
    try:
      participants_email.append(list(User.get(participants_key).index("email_bin", []))[0])
    except NotFoundError:
      raise Exception("User '%s' does not exist!" % participants_key)

  for u in unregistered:
    temp = u.split(" ")
    unregistered_emails.append([temp[0], temp[1][:-1]])

  return {"participants_email" : participants_email, "owners_email" : owners_email, "unregistered_emails" : unregistered_emails}


def add_unregistered_to_project(project, email, t):
  project.addIndex("unregistered_bin", email + " " + t)
  project.save()

def set_owners(project_key, emails):
  project = Project.get(project_key)
  project.removeIndex("owners_bin")
  for email in emails:
    user_queries = User.indexLookup("email_bin", email)
    if len(user_queries) == 0:
      add_unregistered_to_project(project, email, "owners")
    else:
      project.addIndex("owners_bin", user_queries.all()[0].key)

  project.save()
  return True

def set_participants(project_key, emails):
  project = Project.get(project_key)
  project.removeIndex("participants_bin", silent=True)
  if len(emails) == 1 and emails[0] == "":
    project.save()
    return True

  for email in emails:
    user_queries = User.indexLookup("email_bin", email)
    if len(user_queries) == 0:
      add_unregistered_to_project(project, email, "participants")
    else:
      project.addIndex("participants_bin", user_queries.all()[0].key)

  project.save()
  return True

def get_members_list(project_key):
  project = Project.get(project_key)
  members = list(project.index("owners_bin", [])) + list(project.index("participants_bin", []))
  members_list = []
  for member in members:
    u = User.get(member)
    members_list.append({"key" : u.key, "name" : u.name if u.name else list(u.index("email_bin"))[0]})
  return members_list