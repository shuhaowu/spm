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

exports["UserData"] = UserData
exports["Message"] = Message
exports["MessageList"] = MessageList
exports["User"] = User
exports["Project"] = Project