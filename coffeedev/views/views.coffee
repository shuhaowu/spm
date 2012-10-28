exports = namespace "views"

require "views.navbar"
require "views.messages"
require "views.main"

exports["NavBarView"] = views["navbar"]["NavBarView"]
exports["FlashMessagesView"] = views["messages"]["FlashMessagesView"]
exports["MainView"] = views["main"]["MainView"]