exports = namespace "views.project"
models = require "models"

class WallView extends Backbone.View
  tagName: "div"

  initialize: () ->
    _.bindAll(@)
    @wall = new models.Wall()
    @wall_item_template = _.template($("#wall-item").html())
    @name = "wall"

    @el.innerHTML = $("#project-wall-view").html()

    that = this
    @wall.on("add", (item) -> that.add_item(item))
    @wall.on("reset", () -> $(".wall-post-container", that.el).html(""))
    @wall.on("remove", (item, collection) -> that.remove_item(item))

  add_item: (item) ->
    div = $(document.createElement("div")).html(@wall_item_template({post: item})).css("display", "none")
    $(".wall-post-container", @el).prepend(div)
    div.fadeIn()
    item.div = div

  remove_item: (item) ->
    item.div.fadeOut("normal", () -> item.div.remove())

  set_project: (project) ->
    @wall.key = project.get("key")
    if (@options.userdata.get("key") in project.get("owners"))
      $(".wall-poster-container", @el).css("display", "block")
    else
      $(".wall-poster-container", @el).css("display", "none")

    @wall.reset()
    @wall.fetch()

  render: () ->
    @wall.fetch()
    @delegateEvents()
    @el

  on_post_button_clicked: (ev) ->
    ev.preventDefault()
    textarea = $("textarea#wall-add-post-textarea", @el)
    content = $.trim(textarea.val())
    that = this
    if content.length <= 0
      post_message("You need some text for a wall post!", "alert") # use foundation form errors?
    else
      statusmsg.display("Posting...")
      wallpost = new models.WallPost()
      wallpost["project_key"] = @wall.key
      wallpost.set("content", content)
      wallpost.save(null,
        success: (() ->
          that.wall.add(wallpost)
          textarea.val("")
          statusmsg.close()
        )
        error: ((xhr, status, error) -> post_message("Failed to post update (#{xhr.status} #{error})", "alert"))
      )

  on_delete_post_clicked: (ev) ->
    if (confirm("Are you sure you want to delete this post?"))
      ev.preventDefault()
      key = $(ev.target).attr("data-key")
      statusmsg.display("Deleting...")
      @wall.get(key).destroy(
        success: () -> statusmsg.close()
      )

  events:
    "click a#wall-post-button" : "on_post_button_clicked"
    "click a.delete-post" : "on_delete_post_clicked"

class TodoItemView extends Backbone.View

  initialize: () ->
    @template = @options.template
    @todo = @options.todo
    that = this
    @todo.on("destroy", () -> that.on_destroy())

  render: (last=false) ->
    @el.innerHTML = @template({
      todo: @todo,
      possible_assignees: [],
      possible_categories: ["uncategorized", "electrical", "software", "mechanical", "everyone"],
      can_edit: true,
      last: last
    })
    @delegateEvents()
    @el

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

    if editdiv.css("display") == "none"
      if displaydiv.css("display") != "none"
        displaydiv.fadeOut("fast", () -> editdiv.fadeIn("fast"))
      else
        editdiv.slideDown()

  on_close_item_details_clicked: (ev) ->
    ev.preventDefault()
    $(".todo-item-details", @el).slideUp()

  on_close_item_details_edit_clicked: (ev) ->
    ev.preventDefault()
    $(".todo-item-details-edit", @el).slideUp()

  on_checkbox_clicked: (ev) ->
    checkbox = $(ev.target)
    if checkbox.hasClass("checked")
      checkbox.removeClass("checked")
      checkbox.next().removeClass("done")
    else
      checkbox.addClass("checked")
      checkbox.next().addClass("done")

  on_delete_clicked: (ev) ->
    ev.preventDefault()
    if (confirm("Are you sure you want to delete this item?"))
      @todo.destroy()

  on_destroy: () ->
    that = this
    @$el.fadeOut(() -> that.$el.remove())

  on_update_clicked: (ev) ->
    ev.preventDefault()
    duedate = $(".todo-item-details-edit .duedate", @el).val()
    assignee = $(".todo-item-details-edit .assignee", @el).val()
    category = $(".todo-item-details-edit .category", @el).val()
    desc = $(".todo-item-details-edit .desc", @el).val()

    console.log duedate
    console.log assignee
    console.log category
    console.log desc


  events:
    "click .todo-item-details .close" : "on_close_item_details_clicked"
    "click .todo-item-details-edit .close" : "on_close_item_details_edit_clicked"
    "click .todo-item .text" : "on_item_clicked"
    "click .todo-item .checkbox" : "on_checkbox_clicked"
    "click .todo-item .delete" : "on_delete_clicked"
    "click .todo-item .edit" : "on_edit_clicked"
    "click .todo-item-details-update-button" : "on_update_clicked"

class TodoView extends Backbone.View
  tagName: "div"

  initialize: () ->
    _.bindAll(@)
    @name = "todo"
    @todos_list = new models.TodoList()
    @el.innerHTML = document.getElementById("todo-view").innerHTML

    that = this
    @todos_list.on("add", (todo) -> that.add_todo(todo))
    @todos_list.on("reset", () -> that.reset())

    @todo_item_template = _.template(document.getElementById("todo-item-view").innerHTML)

  add_todo: (todo) ->
    view = new TodoItemView({todo: todo, template: @todo_item_template})
    element = $(view.render()).css("display", "none").insertAfter($("#todo-new-container", @el))
    element.fadeIn()

  reset: () ->
    null

  render: () ->
    @delegateEvents()
    @el

  reset: () ->
    $("#todo-items-container").empty()

  set_project: (project) ->
    @project = project
    @todos_list.reset()
    @todos_list.project_key = project.get("key")

  on_add_item_clicked: (ev) ->
    ev.preventDefault()
    $("#todo-new-container").slideDown()

  on_cancel_add_item_clicked: (ev) ->
    ev.preventDefault()
    $("#todo-new-container input").val("")
    $("#todo-new-container").slideUp()

  on_add_item_actual_clicked: (ev) ->
    ev.preventDefault()
    title = $.trim($("#todo-new-container input").val())
    if title and title.length > 0
      todo = new models.TodoItem()
      todo.project_key = @project.get("key")
      todo.set("title", title)
      $("#todo-new-container input").val("")
      @todos_list.add(todo)
    else
      post_message("You need a title for the todo item!", "alert")

  events:
    "click a#todo-add-item" : "on_add_item_clicked"
    "click a#todo-add-item-cancel-button" : "on_cancel_add_item_clicked"
    "click a#todo-add-item-button" : "on_add_item_actual_clicked"

class ProjectView extends Backbone.View
  initialize: () ->
    _.bindAll(@)
    that = this

    @project = new models.Project()
    @template = _.template(@options.template)
    @current_nav_dd = null
    @views =
      wall: new WallView({userdata: @options.userdata, project_view: @})
      todo: new TodoView({userdata: @options.userdata, project_view: @})
      #schedule: "schedule view"
      #file: "file view"
      #discussions: "discussions view"
      #manage: "manage view"
    @current_view = "wall"

    @project.on("change:key", (model, key) ->
      for vname of that.views
        that.views[vname].set_project(model)
    )

  set_project_and_render: (key, page="wall") ->
    that = this
    if @project.get("key") != key
      $.ajax(
        type: "GET"
        url: "/projects/view/#{key}"
        success: ((res, status, xhr) ->
          that.project.set(res)
          that.current_view = that.views[page]
          that.render()
        )
        error: (xhr, status, error) ->
          that.options.mainview.on_loading_error(xhr)
      )
    else
      @render_page(page)

  render_page: (page) ->
    @current_view = @views[page]
    @render()

  render: () ->
    @el.innerHTML = @template({project: @project, todos: @options.userdata.get("todos"), my_key: @options.userdata.get("key")})

    content_view = $("div#project-content-view", @el)
    content_view.empty()
    content_view.append(@current_view.render())

    @update_nav_active($("a#project-#{@current_view.name}-link", @el).parent())

  update_nav_active: (new_dd) ->
    if @current_nav_dd
      @current_nav_dd.removeClass("active")
    @current_nav_dd = new_dd
    new_dd.addClass("active")

  on_nav_link_click: (ev) ->
    @update_nav_active($(ev.target).parent())

  events:
    "click a.project-nav-link" : "on_nav_link_click"

exports["ProjectView"] = ProjectView