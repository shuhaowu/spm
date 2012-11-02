views = require "views"
models = require "models"
statusmsg = require "statusmsg"

_.templateSettings = {
  interpolate : /\{\[([\s\S]+?)\]\}/g,
  evaluate: /\{\@([\s\S]+?)\@\}/g,
};

class AppRouter extends Backbone.Router
  routes:
    "home" : "home"

    "profile/:key" : "show_profile"
    "profile"     : "show_my_profile"

    "p/:key" : "show_project"
    "p/:key/wall" : "show_project_wall"
    "p/:key/schedule" : "show_project_schedule"
    "p/:key/todo" : "show_project_todo"
    "p/:key/file" : "show_project_file"
    "p/:key/discussions" : "show_project_discussions"
    "p/:key/manage" : "show_project_manage"


$(document).ready(
  (e) ->
    #$(document).foundationTopBar();
    #$(document).foundationAlerts();

    statusmsg.setup()
    $.ajaxSetup({dataType: "json"})

    message_collection = new models["MessageList"]()
    window.post_message = (content, type) ->
      message = new models["Message"]({type: type, content: content})
      message_collection.add(message)

    userdata = new models["UserData"]()

    userdata.on("change:loggedin", (model, loggedin) ->
      $(".hidden-until-logged-in").css("visibility", if loggedin then "visible" else "hidden")
      if loggedin
        userdata.update_personalized_data()
    )

    app_router = new AppRouter()

    message_view = new views["FlashMessagesView"]({el: $("div#messages"), message_collection: message_collection})
    main_view = new views["MainView"]({el: $("div#main"), message_collection: message_collection, userdata: userdata, router: app_router})
    login_view = new views["NavBarView"]({el: $("nav.top-bar"), message_collection: message_collection, userdata: userdata})

    app_router.on("route:show_my_profile", () ->
      current_user_key = window.current_user_key || userdata.get("key")
      if current_user_key
        main_view.show_profile(current_user_key)
      else
        main_view.http_error(403)
    )

    app_router.on("route:show_profile", (key) ->
      main_view.show_profile(key)
    )

    app_router.on("route:show_project", (key) ->
      main_view.show_project(key)
    )

    app_router.on("route:show_project_wall", (key) ->
      main_view.show_project(key, "wall")
    )

    app_router.on("route:show_project_todo", (key) ->
      main_view.show_project(key, "todo")
    )

    Backbone.history.start()
)