exports = namespace "views.main"
vp = require "views.profile"
models = require "models"
project = require "views.project"

class MainView extends Backbone.View
  initialize: () ->
    _.bindAll(@)
    that = this
    @current_view = null
    @profile_view = new vp.ProfileView({el: @el, template: $("#profile-view").html(), mainview: this})
    @project_view = new project.ProjectView({el: @el, template: $("#project-view").html(), mainview: this, userdata: @options.userdata})
    $("a#new-project-link").click((ev) -> that.on_new_project_click(ev))

    @options.userdata.on("change:loggedin", (model, loggedin) ->
      if loggedin
        that.on_login()
      else
        that.on_logout()
    )

  on_login: () ->
    if @current_view == null
      @el.innerHTML = ""

  on_logout: () ->
    @login_required()

  show_profile: (key) ->
    if @profile_view != @current_view or @profile_view.user.get("key") != key
      @profile_view.set_user_and_render(key)
      @current_view = @profile_view

  show_project: (key, page="wall") ->
    if @project_view != @current_view or @project_view.project.get("key") != key
      @project_view.set_project_and_render(key, page)
      @current_view = @profile_view

  render: () -> @current_view.render()

  login_required: () ->
    @el.innerHTML = "<h2 class=\"center\">You need to sign in to continue!</h2>"

  on_loading_error: (xhr, status, error) ->
    @http_error(xhr.status)

  http_error: (status) ->
    switch (status)
      when 403
        @el.innerHTML = "<h2 class=\"center\">#{status}: You're not allowed to access this.</h2>"
      when 404
        @el.innerHTML = "<h2 class=\"center\">#{status}: Requested document is not found.</h2>"
      when 405, 400
        @el.innerHTML = "<h2 class=\"center\">#{status}: This request is invalid.</h2>"
      when 500
        @el.innerHTML = "<h2 class=\"center\">#{status}: The server encountered an error.</h2>"

  on_new_project_click: (ev) ->
    ev.preventDefault()
    project_name = $.trim(prompt("Project Name"))
    that = this
    if project_name == ""
      post_message("You need a name for a new project!", "alert")
    else if project_name != null
      $.ajax(
        type: "POST"
        url: "/projects/new"
        data: {name: project_name}
        success: ((res, status, xhr) ->
          that.options.router.navigate("p/#{res['key']}", {trigger: true})
          post_message("New project created!", "success")
        )
        error: ((xhr, status, error) ->
          post_message("Project creation failed (#{xhr.status} #{error}).", "alert")
        )
      )


exports["MainView"] = MainView