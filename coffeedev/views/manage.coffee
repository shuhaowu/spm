exports = namespace "views.manage"
models = require "models"

class ManageView extends Backbone.View
  initialize: () ->
    @template = _.template(document.getElementById("manage-view").innerHTML)

  render: () ->
    that = this
    $.ajax(
      type: "GET"
      url: "/projects/manage/" + @project.get("key") + "/get_emails"
      success: ((response, status, xhr) ->
        that.el.innerHTML = that.template(response)
        that.delegateEvents()
      )
      error: (xhr, status, error) ->
        post_message("Error fetching project info #{xhr.status}", "alert")
    )
    @el

  set_project: (project) ->
    @project = project

  update_people: (group) ->
    statusmsg.display("Updating...")
    emails = $.trim($("#manage-update-#{group}-emails", @el).val()).split(/\r\n|\r|\n/g)
    for email, i in emails
      emails[i] = $.trim(email)

    $.ajax(
      type: "POST"
      url: "/projects/manage/" + @project.get("key") + "/set_#{group}_emails"
      data: JSON.stringify({emails: emails})
      contentType: "application/json"
      success: (response, status, xhr) ->
        statusmsg.close()
        post_message("List successfully updated.", "success")
      error: (xhr, status, error) ->
        statusmsg.close()
        if xhr.status == 400
          post_message("Some of your emails are invalid!", "alert")
        else
          post_message("Something went wrong #{xhr.status}", "alert")
    )

  on_click_update_owners: (ev) ->
    ev.preventDefault()
    @update_people("owners")

  on_click_update_participants: (ev) ->
    ev.preventDefault()
    @update_people("participants")

  events:
    "click a#manage-update-owners-button" : "on_click_update_owners"
    "click a#manage-update-participants-button" : "on_click_update_participants"

exports["ManageView"] = ManageView