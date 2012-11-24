exports = namespace "views.todo"
models = require "models"

class TodoItemDetailsView extends Backbone.View

  initialize: () ->
    _.bindAll(@)
    if TodoItemDetailsView.template == undefined
      TodoItemDetailsView.template = _.template(document.getElementById("todo-item-details-view").innerHTML)

    @todo = @options.todo
    @todo.on("update", @render)

  render: () ->
    that = this
    @el.innerHTML = TodoItemDetailsView.template({
      todo: @todo
      get_user_name: (key) ->
        for u in that.options.parent.options.parent.possible_assignees
          if u["key"] == key
            return u["name"]
        return "Error has occurred here..."
    })
    @delegateEvents()
    @el

  on_close_clicked: (ev) ->
    ev.preventDefault()
    @$el.slideUp()

  events:
    "click a.close" : "on_close_clicked"

class TodoItemDetailsEditView extends Backbone.View
  initialize: () ->
    _.bindAll(@)

    if TodoItemDetailsEditView.template == undefined
      TodoItemDetailsEditView.template = _.template(document.getElementById("todo-item-details-edit-view").innerHTML)

    @todo = @options.todo

  render: () ->
    @el.innerHTML = TodoItemDetailsEditView.template({
      todo: @todo,
      possible_assignees: @options.parent.options.parent.possible_assignees, #wut
      possible_categories: ["uncategorized", "electrical", "mechanical", "software", "everyone"]
    })
    $(".duedate", @el).datepicker()
    @delegateEvents()
    @el

  on_close_clicked: (ev) ->
    ev.preventDefault()
    @$el.slideUp()

  on_update_clicked: (ev) ->
    ev.preventDefault()
    statusmsg.display("Updating todo...")
    converter = new Showdown.converter()
    markdown = $.trim($(".desc", @el).val())
    desc = {html: converter.makeHtml(markdown), markdown: markdown}

    @todo.set("title", $.trim($(".title", @el).val()))
    @todo.set("desc", desc)
    @todo.set("duedate", $.trim($(".duedate", @el).val()))
    @todo.set("assignee", $(".assignee", @el).val())
    @todo.set("categories", [$(".categories", @el).val()])

    that = this
    @todo.save({},
      success: () ->
        that.todo.trigger("update")
        statusmsg.close()
        that.options.parent.switch_to_display()
      error: (model, xhr, options) ->
        post_message("Todo update failed (#{xhr.status})", "alert")
        statusmsg.close()
    )

  events:
    "click a.close" : "on_close_clicked"
    "click a.todo-item-details-update-button" : "on_update_clicked"

class TodoItemView extends Backbone.View

  initialize: () ->
    _.bindAll(@)
    @template = @options.template
    @todo = @options.todo
    that = this
    @options.todos_list.on("remove", (model, collection) ->
      if model.get("key") == that.todo.get("key")
        that.on_destroy()
    )

    @options.todos_list.on("reset", (collection) -> that.on_destroy())

    @todo.on("destroy", () -> that.on_destroy())
    @todo.on("change:title", (model, title) ->
      $(".todo-item span.text", that.el).text(title)
    )

    hide_todo_when_done = (todo, done) ->
      if done
        that.$el.fadeOut()

    @todo.on("hidedone", () ->
      that.todo.on("change:done", hide_todo_when_done)
      if that.todo.get("done") and that.$el.css("display") != "none"
        that.$el.fadeOut()
    )

    @todo.on("showdone", () ->
      that.todo.off("change:done", hide_todo_when_done)
      if that.$el.css("display") == "none"
        that.$el.fadeIn()
    )

    @details_view = null
    @details_edit_view = null


  render: (last=false) ->
    @el.innerHTML = @template(
      todo: @todo
      can_edit: true
      last: last
      current_time: Date.parse(new Date())
    )

    @delegateEvents()

    if @details_view == null
      @details_view = new TodoItemDetailsView(
        todo: @todo
        parent: this
        el: $(".todo-item-details", @el)
      )

    @details_view.render()

    if @details_edit_view == null
      @details_edit_view = new TodoItemDetailsEditView(
        todo: @todo
        parent: this
        el: $(".todo-item-details-edit", @el)
      )

    @details_edit_view.render()

    @el

  switch_details_view: (new_view, old_view) ->
    if new_view.css("display") == "none"
      if old_view.css("display") != "none"
        old_view.fadeOut("fast", () -> new_view.fadeIn("fast"))
      else
        new_view.slideDown()

  switch_to_display: () ->
    displaydiv = $(".todo-item-details", @el)
    editdiv = $(".todo-item-details-edit", @el)

    @switch_details_view(displaydiv, editdiv)

  on_item_clicked: (ev) ->
    displaydiv = $(".todo-item-details", @el)
    editdiv = $(".todo-item-details-edit", @el)

    if displaydiv.css("display") == "none"
      if editdiv.css("display") != "none"
        editdiv.fadeOut("fast", () -> displaydiv.fadeIn("fast"))
      else
        displaydiv.slideDown()
    else
      displaydiv.slideUp()

  on_edit_clicked: (ev) ->
    ev.preventDefault()
    displaydiv = $(".todo-item-details", @el)
    editdiv = $(".todo-item-details-edit", @el)
    @switch_details_view(editdiv, displaydiv)

  on_checkbox_clicked: (ev) ->
    checkbox = $(ev.target)
    that = this
    $.ajax(
      type: "POST"
      url: "/projects/todo/#{@todo.project_key}/done/#{@todo.get('key')}"
      data: JSON.stringify({done: not checkbox.hasClass("checked")})
      contentType: 'application/json'
      success: (data, status, xhr) ->
        if checkbox.hasClass("checked")
          that.todo.set("done", false) # hack.. this should be done in a better way...
          checkbox.removeClass("checked")
          checkbox.next().removeClass("done")
        else
          that.todo.set("done", true)
          checkbox.addClass("checked")
          checkbox.next().addClass("done")
      error: (xhr, status, error) ->
        post_message("Error marking todo item (#{xhr.status} #{error})", "alert")
    )

  on_delete_clicked: (ev) ->
    ev.preventDefault()
    if (confirm("Are you sure you want to delete this item?"))
      statusmsg.display("Deleting...")
      @todo.destroy({
        success: (() -> statusmsg.close())
        error: ((model, xhr) ->
          statusmsg.close()
          post_message("Deleting failed... #{xhr.status}", "alert")
        )
      })

  on_destroy: () ->
    that = this
    @$el.fadeOut(() -> that.$el.remove())

  events:
    "click .todo-item .text" : "on_item_clicked"
    "click .todo-item .checkbox" : "on_checkbox_clicked"
    "click .todo-item .delete" : "on_delete_clicked"
    "click .todo-item .edit" : "on_edit_clicked"

class TodoView extends Backbone.View
  tagName: "div"

  initialize: () ->
    _.bindAll(@)
    @name = "todo"
    @todos_list = new models.TodoList()

    @el.innerHTML = document.getElementById("todo-view").innerHTML

    that = this
    @todos_list.on("add", (todo) -> that.add_todo(todo))

    @todo_item_template = _.template(document.getElementById("todo-item-view").innerHTML)

  add_todo: (todo) ->
    if todo.get("duedate") # hack.. because this will always be undefined when adding a todo from the view... so it must be from server otherwise
      todo.set("duedate", (new Date(todo.get("duedate") * 1000)).toLocaleFormat("%m/%d/%Y"))
    view = new TodoItemView({todo: todo, template: @todo_item_template, todos_list: @todos_list, parent: this})
    element = $(view.render()).css("display", "none").insertAfter($("#todo-new-container", @el))
    element.fadeIn()

  render: () ->
    @todos_list.fetch() # has reset
    @delegateEvents()
    @el

  set_project: (project) ->
    @project = project
    @todos_list.project_key = project.get("key")
    that = this
    $.ajax(
      type: "GET"
      url: "/projects/members/" + project.get("key")
      success: ((data, status, xhr) ->
        that.possible_assignees = data["items"]
      ),
      error: (xhr, status, error) ->
        post_message("Something went wrong... try reloading the page (Loading assignee failed #{xhr.status})", "alert")
    )

  on_add_item_clicked: (ev) ->
    ev.preventDefault()
    $("#todo-new-container", @el).slideDown()

  on_cancel_add_item_clicked: (ev) ->
    ev.preventDefault()
    $("#todo-new-container input", @el).val("")
    $("#todo-new-container", @el).slideUp()

  on_add_item_actual_clicked: (ev) ->
    ev.preventDefault()
    title = $.trim($("#todo-new-container input").val())
    if title and title.length > 0
      statusmsg.display("Adding todo...")
      todo = new models.TodoItem()
      todo.project_key = @project.get("key")
      todo.set("title", title)
      that = this
      todo.save({},
        success: () ->
          $("#todo-new-container input").val("")
          that.todos_list.add(todo)
          statusmsg.close()
        error: () ->
          post_message("Adding todo failed.", "alert")
          statusmsg.close()
      )
    else
      post_message("You need a title for the todo item!", "alert")

  on_filter_done: (ev) ->
    ev.preventDefault()

    target = $(ev.target)
    if target.attr("data-hide-done") == "0"
      hide_done = true
      target.attr("data-hide-done", "1")
      target.text("Show done")
    else
      hide_done = false
      target.attr("data-hide-done", "0")
      target.text("Hide done")

    @todos_list.each((item) ->
      item.trigger(if hide_done then "hidedone" else "showdone")
    )

  events:
    "click a#todo-add-item" : "on_add_item_clicked"
    "click a#todo-add-item-cancel-button" : "on_cancel_add_item_clicked"
    "click a#todo-add-item-button" : "on_add_item_actual_clicked"
    "click a#todo-filter-done" : "on_filter_done"


exports["TodoView"] = TodoView