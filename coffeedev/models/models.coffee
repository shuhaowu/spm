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
            that.add(new WallPost(post))
        )
        error: (xhr, status, error) ->
          post_message("Failed to update wall (#{xhr.status} {error})", "alert")
      )

exports["UserData"] = UserData
exports["Message"] = Message
exports["MessageList"] = MessageList
exports["User"] = User
exports["Project"] = Project
exports["Wall"] = Wall
exports["WallPost"] = WallPost