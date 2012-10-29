exports = namespace "views.navbar"
models = require "models"

class NavBarView extends Backbone.View

  initialize: () ->
    _.bindAll(@)
    @login_link = $("a#persona-login")
    @profile_link = $("li#profile-link a")

    @logindata = @options.logindata
    that = this
    @logindata.on("change:loggedin", (model, loggedin) ->
      if loggedin
        that.login_link.text("Logout")
        that.profile_link.css("visibility", "visible")
      else
        that.login_link.text("Login with Your Email")
        that.profile_link.css("visibility", "hidden")
    )

    if window.current_user
      @logindata.set("loggedin", true)
      @logindata.set("current_user", window.current_user)
      @logindata.set("current_user_key", window.current_user_key)

    that = this
    navigator.id.watch({
      loggedInUser: window.current_user,
      onlogin: ((assertion) ->
        $.ajax({
        type: "POST",
        url: "/login/",
        data: {assertion: assertion},
        success: ((res, status, xhr) ->
          if res["status"] == "okay"
            that.logindata.set("loggedin", true)
            that.logindata.set("current_user", res["email"])
            that.logindata.set("current_user_key", res["key"])
            post_message("You have logged in as #{res['email']}.", "success")
          else
            that.on_error(res, status)
          ),
        error: ((res, status, xhr) -> that.on_error(res, status))
        })
      ),
      onlogout: (() ->
        if that.logindata.get("loggedin")
          $.ajax({
            type: "GET",
            url: "/logout/",
            success: ((res, status, xhr) ->
              that.logindata.set("loggedin", false)
              that.logindata.set("current_user", undefined)
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
    if (@logindata.get("loggedin"))
      @login_link.text("Signing out, please wait...")
      navigator.id.logout()
    else
      @login_link.text("Signing in, please wait...")
      navigator.id.request()

  events:
    "click a#persona-login" : "on_login_click"

exports["NavBarView"] = NavBarView