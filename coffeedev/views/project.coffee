exports = namespace "views.project"
models = require "models"
todo = require "views.todo"
schedule = require "views.schedule"

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


  render: () ->
    @wall.reset()
    @wall.fetch() # don't need to delegate events in success because the events here are not modified when fetch is called (that's item view)
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
    ev.preventDefault()
    if (confirm("Are you sure you want to delete this post?"))
      key = $(ev.target).attr("data-key")
      statusmsg.display("Deleting...")
      @wall.get(key).destroy(
        success: () -> statusmsg.close()
      )

  events:
    "click a#wall-post-button" : "on_post_button_clicked"
    "click a.delete-post" : "on_delete_post_clicked"

class ProjectView extends Backbone.View
  initialize: () ->
    _.bindAll(@)
    that = this

    @project = new models.Project()
    @template = _.template(@options.template)
    @current_nav_dd = null
    @views =
      wall: new WallView({userdata: @options.userdata, project_view: @})
      todo: new todo.TodoView({userdata: @options.userdata, project_view: @})
      schedule: new schedule.ScheduleView({userdata: @options.userdata, project_view: @})
      #file: "file view"
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