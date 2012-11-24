exports = namespace "views.file"

class FileView extends Backbone.View
  initialize: () ->
    @name = "file"

  set_project: (project) ->
    @project = project

  render: () ->
    @el.innerHTML = "<h2 class='center'>501: Not yet implemented</h2>"
    @el

exports["FileView"] = FileView