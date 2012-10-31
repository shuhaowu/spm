exports = namespace "views.navbar"
models = require "models"

class NavBarView extends Backbone.View

  initialize: () ->
    _.bindAll(@)
    @login_link = $("a#persona-login")
    @profile_link = $("li#profile-link a")
    @projects_dropdown = $("#project-dropdown")
    @projects_dropdown_template = _.template(@projects_dropdown.html())
    @projects_dropdown.html("")

    @userdata = @options.userdata
    that = this
    @userdata.on("change:loggedin", (model, loggedin) ->
      if loggedin
        that.login_link.text("Logout")
      else
        that.login_link.text("Login with Your Email")
    )

    @userdata.on("change:projects", (model, projects) ->
      if projects.length > 0
        $("li#project-dropdown-li").css("visibility", "visible")
        that.projects_dropdown.html(that.projects_dropdown_template({projects: projects}))
      else
        $("li#project-dropdown-li").css("visibility", "hidden")
    )

    if window.current_user_email
      @userdata.set("loggedin", true)
      @userdata.set("email", window.current_user_email)
      @userdata.set("key", window.current_user_key)

    that = this
    navigator.id.watch({
      loggedInUser: window.current_user_email,
      onlogin: ((assertion) ->
        $.ajax({
        type: "POST",
        url: "/login/",
        data: {assertion: assertion},
        success: ((res, status, xhr) ->
          if res["status"] == "okay"
            that.userdata.set("loggedin", true)
            that.userdata.set("email", res["email"])
            that.userdata.set("key", res["key"])
            post_message("You have logged in as #{res['email']}.", "success")
          else
            that.on_error(res, status)
          ),
        error: ((res, status, xhr) -> that.on_error(res, status))
        })
      ),
      onlogout: (() ->
        if that.userdata.get("loggedin")
          $.ajax({
            type: "GET",
            url: "/logout/",
            success: ((res, status, xhr) ->
              that.userdata.clear({silent: true})
              that.userdata.set("loggedin", false)
              post_message("You have been logged out.", "success")
            ),
            error: (res, status, xhr) -> that.on_error(res, status)
          })
      )
    })

  on_error: (res, status) ->
    console.log res
    post_message("Authentication Error: #{res['status']} #{res['statusText']}", "alert")

  on_login_click: () ->
    if (@userdata.get("loggedin"))
      @login_link.text("Signing out, please wait...")
      navigator.id.logout()
    else
      @login_link.text("Signing in, please wait...")
      navigator.id.request()

  events:
    "click a#persona-login" : "on_login_click"

exports["NavBarView"] = NavBarView