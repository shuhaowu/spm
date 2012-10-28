exports = namespace "views.profile"
models = require "models"

class ProfileView extends Backbone.View
  initialize: ()->
    _.bindAll(@)

    @user = new models.User()
    @template = _.template(@options.template)

  set_user_and_render: (key) ->
    that = this
    $.ajax({
      type: "GET",
      url: "/profile/#{key}",
      success: ((data, status, xhr) ->
        data["name"] or (data["name"] = "Unknown")
        that.user.set(data, {silent: true})
        that.render()
      ),
      error: ((xhr, status, error) ->
        that.options.mainview.on_loading_error(xhr, status, error)
      )
    })

  render: () ->
    @el.innerHTML = @template({user: @user})

  events:
    "click a#profile-change-name" : "on_change_name_clicked"
    "click a#profile-cancel-change-name" : "on_cancel_change_name_clicked"

  on_cancel_change_name_clicked: (ev) ->
    ev.preventDefault()
    $(".profile-name span").attr("contentEditable", false).text(@user.get("name")).css("border", "0")
    $("a#profile-change-name").text("Change")
    $("a#profile-cancel-change-name").css("visibility", "hidden")

  on_change_name_clicked: (ev) ->
    ev.preventDefault()
    link = $("a#profile-change-name")
    namespan = $(".profile-name span")
    cancel = $("a#profile-cancel-change-name")

    if link.text() == "Change"
      namespan.attr("contentEditable", true).css("border", "1px dotted black")
      link.text("Save")
      cancel.css("visibility", "visible")
    else
      link.text("Saving...")
      cancel.css("visibility", "hidden")
      that = this
      $.ajax(
        type: "POST"
        url: "/profile/changename"
        data: {name: namespan.text()}
        success: ((data, status, xhr) ->
          that.user.set("name", namespan.text)
          namespan.attr("contentEditable", false).css("border", "0")
          post_message("Your name was updated", "success")
          link.text("Change")
          cancel.css("visibility", "hidden")
        )
        error: (xhr, status, error) ->
          post_message("Something went wrong updating your name: #{xhr.status} #{error}", "alert")
          link.text("Save")
          cancel.css("visibility", "visible")
      )

exports["ProfileView"] = ProfileView