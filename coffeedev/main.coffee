views = require "views"
models = require "models"

_.templateSettings = {
  interpolate : /\{\[([\s\S]+?)\]\}/g,
  evaluate: /\{\@([\s\S]+?)\@\}/g,
};

class AppRouter extends Backbone.Router
  routes:
    "home" : "home"
    "p/:key" : "show_project"
    "profile/:key" : "show_profile"
    "profile"     : "show_my_profile"

$(document).ready(
  (e) ->
    #$(document).foundationTopBar();
    #$(document).foundationAlerts();

    $.ajaxSetup({dataType: "json"})

    message_collection = new models["MessageList"]()
    window.post_message = (content, type) ->
      message = new models["Message"]({type: type, content: content})
      message_collection.add(message)

    logindata = new models["LoginData"]()

    message_view = new views["FlashMessagesView"]({el: $("div#messages"), message_collection: message_collection})
    main_view = new views["MainView"]({el: $("div#main"), message_collection: message_collection, logindata: logindata})
    login_view = new views["NavBarView"]({el: $("nav.top-bar"), message_collection: message_collection, logindata: logindata})

    app_router = new AppRouter()
    app_router.on("route:show_my_profile", () ->
      current_user_key = window.current_user_key || logindata.get("current_user_key")
      if current_user_key
        main_view.show_profile(current_user_key)
      else
        main_view.http_error(403)
    )

    app_router.on("route:show_profile", (key) ->
      main_view.show_profile(key)
    )
    Backbone.history.start()
)