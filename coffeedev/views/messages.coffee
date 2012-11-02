exports = namespace "views.messages"
models = require "models"

class SingleFlashMessageView extends Backbone.View

  tagName: "div"

  initialize: (option) ->
    _.bindAll(@)

  events:
    "click a.close" : "remove"

  remove: (ev) ->
    ev.preventDefault()
    @model.destroy()
    $(@el).fadeOut()

  render: () ->
    @el.innerHTML = @options.template({message: @model})
    @el


class FlashMessagesView extends Backbone.View

  initialize: () ->
    _.bindAll(@)
    @template = _.template(@el.innerHTML)
    @el.innerHTML = ""

    that = this
    @options.message_collection.bind("add", (message) -> that.add_message(message))

  add_message: (message) ->
    mview = new SingleFlashMessageView({model: message, template: @template})
    mnode = $(mview.render()).css("display", "none")
    $(@el).append(mnode)
    mnode.fadeIn()

exports["FlashMessagesView"] = FlashMessagesView