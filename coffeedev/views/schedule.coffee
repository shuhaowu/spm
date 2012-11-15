exports = namespace "views.schedule"
models = require "models"

class ScheduleItemView extends Backbone.View
  tagName: "tr"

  initialize: () ->
    _.bindAll(@)
    @template = _.template(document.getElementById("schedule-single-item-view").innerHTML)
    @details_template = _.template(document.getElementById("schedule-details-view").innerHTML)
    @model = @options.schedule
    @can_manage = @options.can_manage
    @model.on("destroy", @on_destroy)

  on_destroy: () ->
    null

  render: () ->
    @el.innerHTML = @template($.extend(@model.toJSON(), {can_manage: @can_manage}))
    @el

  show_item_details_modal: (ev) ->
    ev.preventDefault()
    $("#shared-modal-content").html(@details_template(@model.toJSON()))
    $("#shared-modal").reveal()

  on_delete_item_clicked: (ev) ->
    ev.preventDefault()
    if confirm("Are you sure you want to delete this event?")
      statusmsg.display("Deleting...")
      that = this
      @model.destroy(
        success: (() ->
          statusmsg.close()
          that.$el.fadeOut(() -> that.$el.remove())
        )
        error: ((model, xhr, options) ->
          statusmsg.close()
          post_message("Error deleting meeting (#{xhr.status})", "alert")
        )
      )

  events:
    "click a.meeting-item-desc-link" : "show_item_details_modal"
    "click a.meeting-item-delete" : "on_delete_item_clicked"


class ScheduleView extends Backbone.View
  initialize: () ->
    _.bindAll(@)
    @template = _.template(document.getElementById("schedule-view").innerHTML)
    @detail_modal_template = _.template(document.getElementById("schedule-details-view").innerHTML)
    @project = null
    @name = "schedule"

    @schedules = new models.Schedules()
    that = this
    @schedules.on("add", (schedule) -> that.on_add_schedule(schedule))

  set_project: (project) ->
    @project = project
    @schedules.project_key = project.get("key")

  on_add_schedule: (schedule, which) ->
    schedule_item_view = new ScheduleItemView({schedule: schedule, can_manage: true})
    schedule_item_view.render()
    node = schedule_item_view.$el
    node.css("display", "none")
    which = if Date.parse(schedule.get("endtime")) > (new Date().getTime()) then "upcoming" else "previous"
    $("tbody#meetings-#{which}", @el).prepend(node)
    node.fadeIn("fast")

  render: () ->
    @schedules.fetch()
    @el.innerHTML = @template(
      can_manage: true
      upcoming_meetings: []
      previous_meetings: []
      nextmeeting: false
      render_item: @render_item
    )
    $(".datetimepicker", @el).datetimepicker()
    @delegateEvents()
    @el

  on_add_meeting_clicked: (ev) ->
    ev.preventDefault()
    meetingbox = $("#meeting-add-box", @el)
    if meetingbox.css("display") == "none"
      meetingbox.slideDown()

  on_meeting_add_box_close_clicked: (ev) ->
    ev.preventDefault()
    meetingbox = $("#meeting-add-box", @el)
    if meetingbox.css("display") != "none"
      that = this
      meetingbox.slideUp(() ->
        that.clear_new_meeting_form()
      )

  clear_new_meeting_form: () ->
    meetingbox = $("#meeting-add-box", @el)
    $("#meeting-new-title", meetingbox).val("").removeClass("error").next("small.error").remove()
    $("#meeting-new-location", meetingbox).val("").removeClass("error").next("small.error").remove()
    $("#meeting-new-desc", meetingbox).val("").removeClass("error").next("small.error").remove()
    $("#meeting-new-start-time", meetingbox).val("").removeClass("error").next("small.error").remove()
    $("#meeting-new-end-time", meetingbox).val("").removeClass("error").next("small.error").remove()

  on_meeting_actually_add: (ev) ->
    ev.preventDefault()
    statusmsg.display("Adding...")
    meetingbox = $("#meeting-add-box", @el)
    title = $.trim($("#meeting-new-title", meetingbox).val())
    location = $.trim($("#meeting-new-location", meetingbox).val())

    desc = $("#meeting-new-desc", meetingbox).val()
    converter = new Showdown.converter()
    markdown = $.trim(desc)
    desc = {html: converter.makeHtml(markdown), markdown: markdown}

    starttime = $.trim($("#meeting-new-start-time", meetingbox).val())
    endtime = $.trim($("#meeting-new-end-time", meetingbox).val())

    meeting = new models.Schedule()
    meeting.project_key = @project.get("key")

    meeting.on("error", (model, error) ->
      statusbox.close()
      for k of error
        # O_O
        $(document.createElement("small")).addClass("error").text(error[k]).insertAfter($("#meeting-new-#{k}", meetingbox).addClass("error"))
    )

    meeting = meeting.set(
      title: title
      location: location
      starttime: starttime
      endtime: endtime
      desc: desc
    )

    if meeting
      that = this
      meeting.save({},
        success: (() ->
          statusmsg.close()
          that.schedules.add(meeting)
          meetingbox.slideUp(() ->
            that.clear_new_meeting_form()
          )
        )
        error: (model, xhr, options) ->
          statusmsg.close()
          post_message("An error has occured while posting to server (#{xhr.status}).", "alert")
      )

  events:
    "click a#add-meeting" : "on_add_meeting_clicked"
    "click a.close" : "on_meeting_add_box_close_clicked"
    "click a#meeting-new-cancel" : "on_meeting_add_box_close_clicked"
    "click a#meeting-new-add" : "on_meeting_actually_add"

exports["ScheduleView"] = ScheduleView