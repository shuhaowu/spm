exports = namespace "models"

class LoginData extends Backbone.Model

  defaults:
    loggedin: false
    current_user: window.current_user

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


exports["LoginData"] = LoginData
exports["Message"] = Message
exports["MessageList"] = MessageList
exports["User"] = User