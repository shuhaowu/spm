exports = namespace "models"

class UserData extends Backbone.Model

  defaults:
    loggedin: false
    email: window.current_user_email
    key: window.current_user_key

  update_personalized_data: () ->
    that = this
    $.ajax(
      type: "GET"
      url: "/mydata"
      success: ((res, status, xhr) ->
        that.set(res)
      )
      error: ((xhr, status, error) ->
        post_message("Something has gone wrong: #{xhr.stats} #{error}", "alert")
      )
    )

class Message extends Backbone.Model
  defaults:
    type: ""

class MessageList extends Backbone.Collection
  model: Message

class User extends Backbone.Model
  urlRoot: "/profile"
  defaults:
    name : "Unknown"
    error: false

class Project extends Backbone.Model

class WallPost extends Backbone.Model
  urlRoot: () -> "/projects/wall/" + @project_key
  idAttribute: "key"

class Wall extends Backbone.Collection
  model: WallPost

  initialize: () ->
    @key = undefined

  fetch: () ->
    if @key != undefined
      that = this
      $.ajax(
        type: "GET"
        url: "/projects/wall/#{that.key}"
        success: ((res, status, xhr) ->
          for post in res["posts"]
            wallpost = new WallPost(post)
            wallpost.project_key = that.key
            that.add(wallpost)
        )
        error: (xhr, status, error) ->
          post_message("Failed to update wall (#{xhr.status} {error})", "alert")
      )

class TodoItem extends Backbone.Model
  urlRoot: () -> "/projects/todo/" + @project_key
  idAttribute: "key"

  defaults:
    "done": false

  initialize: () ->
    if not @get("categories")
      @set("categories", [], {silent: true})

class TodoList extends Backbone.Collection
  model: TodoItem

  initialize: () ->
    @project_key = undefined

  fetch: () ->
    if @project_key != undefined
      that = this
      $.ajax(
        type: "GET"
        url: "/projects/todo/" + that.project_key
        success: (data, status, xhr) ->
          that.reset()
          for todo_json in data["items"]
            todo = new TodoItem(todo_json)
            todo.project_key = that.project_key
            that.add(todo)
        error: (xhr, status, error) ->
          post_message("Error loading todo list (#{xhr.status} #{error})", "alert")
      )

exports["UserData"] = UserData
exports["Message"] = Message
exports["MessageList"] = MessageList
exports["User"] = User
exports["Project"] = Project
exports["Wall"] = Wall
exports["WallPost"] = WallPost
exports["TodoList"] = TodoList
exports["TodoItem"] = TodoItem