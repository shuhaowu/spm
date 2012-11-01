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

  add_item: (item) ->
    div = $(document.createElement("div")).html(@wall_item_template({post: item})).css("display", "none")
    $(".wall-post-container", @el).prepend(div)
    div.fadeIn()

  set_project: (project) ->
    @wall.key = project.get("key")
    if (@options.userdata.get("key") in project.get("owners"))
      $(".wall-poster-container", @el).css("display", "block")
    else
      $(".wall-poster-container", @el).css("display", "none")

    @wall.reset()
    @wall.fetch()

  render: () -> @el

  on_post_button_clicked: (ev) ->
    ev.preventDefault()
    textarea = $("textarea#wall-add-post-textarea", @el)
    content = $.trim(textarea.val())
    that = this
    if content.length <= 0
      post_message("You need some text for a wall post!", "alert") # use foundation form errors?
    else
      $.ajax(
        type: "POST"
        url: "/projects/wall/#{that.wall.key}/add"
        data: {content: content}
        success: ((res, status, xhr) ->
          post_message("Added a wall post!", "success")
          that.wall.add(new models.WallPost(res["post"]))
          textarea.val("")
        )
        error: (xhr, status, error) ->
          post_message("Failed to post update (#{xhr.status} #{error})", "alert")
      )

  events:
    "click a#wall-post-button" : "on_post_button_clicked"

class ProjectView extends Backbone.View
  initialize: () ->
    _.bindAll(@)
    that = this

    @project = new models.Project()
    @template = _.template(@options.template)
    @current_nav_dd = null
    @views =
      wall: new WallView({userdata: @options.userdata})
      #schedule: "schedule view"
      #todo: "todo view"
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
    @render(true)

  render: (update=false) ->
    if not update
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