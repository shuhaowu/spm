// Generated via coffeecrispt

window['require'] = window['module'] = window['namespace'] = function(name){
  var levels = name.split('.');
  var _module = window;
  for (var i=0; i<levels.length; i++){
    if (_module[levels[i]] === undefined)
      _module[levels[i]] = {};
    _module = _module[levels[i]];
  }
  return _module;
};


// coffeedev/models/models.coffee
(function() {
  var LoginData, Message, MessageList, Project, User, exports,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  exports = namespace("models");

  LoginData = (function(_super) {

    __extends(LoginData, _super);

    function LoginData() {
      return LoginData.__super__.constructor.apply(this, arguments);
    }

    LoginData.prototype.defaults = {
      loggedin: false,
      current_user: window.current_user
    };

    return LoginData;

  })(Backbone.Model);

  Message = (function(_super) {

    __extends(Message, _super);

    function Message() {
      return Message.__super__.constructor.apply(this, arguments);
    }

    Message.prototype.defaults = {
      type: ""
    };

    return Message;

  })(Backbone.Model);

  MessageList = (function(_super) {

    __extends(MessageList, _super);

    function MessageList() {
      return MessageList.__super__.constructor.apply(this, arguments);
    }

    MessageList.prototype.model = Message;

    return MessageList;

  })(Backbone.Collection);

  User = (function(_super) {

    __extends(User, _super);

    function User() {
      return User.__super__.constructor.apply(this, arguments);
    }

    User.prototype.urlRoot = "/profile";

    User.prototype.defaults = {
      name: "Unknown",
      error: false
    };

    return User;

  })(Backbone.Model);

  Project = (function(_super) {

    __extends(Project, _super);

    function Project() {
      return Project.__super__.constructor.apply(this, arguments);
    }

    return Project;

  })(Backbone.Model);

  exports["LoginData"] = LoginData;

  exports["Message"] = Message;

  exports["MessageList"] = MessageList;

  exports["User"] = User;

  exports["Project"] = Project;

}).call(this);


// coffeedev/views/messages.coffee
(function() {
  var FlashMessagesView, SingleFlashMessageView, exports, models,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  exports = namespace("views.messages");

  models = require("models");

  SingleFlashMessageView = (function(_super) {

    __extends(SingleFlashMessageView, _super);

    function SingleFlashMessageView() {
      return SingleFlashMessageView.__super__.constructor.apply(this, arguments);
    }

    SingleFlashMessageView.prototype.tagName = "div";

    SingleFlashMessageView.prototype.initialize = function(option) {
      return _.bindAll(this);
    };

    SingleFlashMessageView.prototype.events = {
      "click a.close": "remove"
    };

    SingleFlashMessageView.prototype.remove = function(ev) {
      ev.preventDefault();
      this.model.destroy();
      return $(this.el).fadeOut();
    };

    SingleFlashMessageView.prototype.render = function() {
      this.el.innerHTML = this.options.template({
        message: this.model
      });
      return this.el;
    };

    return SingleFlashMessageView;

  })(Backbone.View);

  FlashMessagesView = (function(_super) {

    __extends(FlashMessagesView, _super);

    function FlashMessagesView() {
      return FlashMessagesView.__super__.constructor.apply(this, arguments);
    }

    FlashMessagesView.prototype.initialize = function() {
      var that;
      _.bindAll(this);
      this.template = _.template(this.el.innerHTML);
      this.el.innerHTML = "";
      that = this;
      return this.options.message_collection.bind("add", function(message) {
        return that.add_message(message);
      });
    };

    FlashMessagesView.prototype.add_message = function(message) {
      var mview;
      mview = new SingleFlashMessageView({
        model: message,
        template: this.template
      });
      return $(this.el).append(mview.render());
    };

    return FlashMessagesView;

  })(Backbone.View);

  exports["FlashMessagesView"] = FlashMessagesView;

}).call(this);


// coffeedev/views/navbar.coffee
(function() {
  var NavBarView, exports, models,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  exports = namespace("views.navbar");

  models = require("models");

  NavBarView = (function(_super) {

    __extends(NavBarView, _super);

    function NavBarView() {
      return NavBarView.__super__.constructor.apply(this, arguments);
    }

    NavBarView.prototype.initialize = function() {
      var that;
      _.bindAll(this);
      this.login_link = $("a#persona-login");
      this.profile_link = $("li#profile-link a");
      this.logindata = this.options.logindata;
      that = this;
      this.logindata.on("change:loggedin", function(model, loggedin) {
        if (loggedin) {
          that.login_link.text("Logout");
          return that.profile_link.css("visibility", "visible");
        } else {
          that.login_link.text("Login with Your Email");
          return that.profile_link.css("visibility", "hidden");
        }
      });
      if (window.current_user) {
        this.logindata.set("loggedin", true);
        this.logindata.set("current_user", window.current_user);
        this.logindata.set("current_user_key", window.current_user_key);
      }
      that = this;
      return navigator.id.watch({
        loggedInUser: window.current_user,
        onlogin: (function(assertion) {
          return $.ajax({
            type: "POST",
            url: "/login/",
            data: {
              assertion: assertion
            },
            success: (function(res, status, xhr) {
              if (res["status"] === "okay") {
                that.logindata.set("loggedin", true);
                that.logindata.set("current_user", res["email"]);
                that.logindata.set("current_user_key", res["key"]);
                return post_message("You have logged in as " + res['email'] + ".", "success");
              } else {
                return that.on_error(res, status);
              }
            }),
            error: (function(res, status, xhr) {
              return that.on_error(res, status);
            })
          });
        }),
        onlogout: (function() {
          if (that.logindata.get("loggedin")) {
            return $.ajax({
              type: "GET",
              url: "/logout/",
              success: (function(res, status, xhr) {
                that.logindata.set("loggedin", false);
                that.logindata.set("current_user", void 0);
                return post_message("You have been logged out.", "success");
              }),
              error: function(res, status, xhr) {
                return that.on_error(res, status);
              }
            });
          }
        })
      });
    };

    NavBarView.prototype.on_error = function(res, status) {
      console.log(res);
      return post_message("Authentication Error: " + res['status'] + " " + res['statusText'], "alert");
    };

    NavBarView.prototype.on_login_click = function() {
      if (this.logindata.get("loggedin")) {
        this.login_link.text("Signing out, please wait...");
        return navigator.id.logout();
      } else {
        this.login_link.text("Signing in, please wait...");
        return navigator.id.request();
      }
    };

    NavBarView.prototype.events = {
      "click a#persona-login": "on_login_click"
    };

    return NavBarView;

  })(Backbone.View);

  exports["NavBarView"] = NavBarView;

}).call(this);


// coffeedev/views/profile.coffee
(function() {
  var ProfileView, exports, models,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  exports = namespace("views.profile");

  models = require("models");

  ProfileView = (function(_super) {

    __extends(ProfileView, _super);

    function ProfileView() {
      return ProfileView.__super__.constructor.apply(this, arguments);
    }

    ProfileView.prototype.initialize = function() {
      _.bindAll(this);
      this.user = new models.User();
      return this.template = _.template(this.options.template);
    };

    ProfileView.prototype.set_user_and_render = function(key) {
      var that;
      that = this;
      return $.ajax({
        type: "GET",
        url: "/profile/" + key,
        success: (function(data, status, xhr) {
          data["name"] || (data["name"] = "Unknown");
          that.user.set(data, {
            silent: true
          });
          return that.render();
        }),
        error: (function(xhr, status, error) {
          return that.options.mainview.on_loading_error(xhr, status, error);
        })
      });
    };

    ProfileView.prototype.render = function() {
      return this.el.innerHTML = this.template({
        user: this.user
      });
    };

    ProfileView.prototype.events = {
      "click a#profile-change-name": "on_change_name_clicked",
      "click a#profile-cancel-change-name": "on_cancel_change_name_clicked"
    };

    ProfileView.prototype.on_cancel_change_name_clicked = function(ev) {
      ev.preventDefault();
      $(".profile-name span").attr("contentEditable", false).text(this.user.get("name")).css("border", "0");
      $("a#profile-change-name").text("Change");
      return $("a#profile-cancel-change-name").css("visibility", "hidden");
    };

    ProfileView.prototype.on_change_name_clicked = function(ev) {
      var cancel, link, namespan, that;
      ev.preventDefault();
      link = $("a#profile-change-name");
      namespan = $(".profile-name span");
      cancel = $("a#profile-cancel-change-name");
      if (link.text() === "Change") {
        namespan.attr("contentEditable", true).css("border", "1px dotted black");
        link.text("Save");
        return cancel.css("visibility", "visible");
      } else {
        link.text("Saving...");
        cancel.css("visibility", "hidden");
        that = this;
        return $.ajax({
          type: "POST",
          url: "/profile/changename",
          data: {
            name: namespan.text()
          },
          success: (function(data, status, xhr) {
            that.user.set("name", namespan.text);
            namespan.attr("contentEditable", false).css("border", "0");
            post_message("Your name was updated", "success");
            link.text("Change");
            return cancel.css("visibility", "hidden");
          }),
          error: function(xhr, status, error) {
            post_message("Something went wrong updating your name: " + xhr.status + " " + error, "alert");
            link.text("Save");
            return cancel.css("visibility", "visible");
          }
        });
      }
    };

    return ProfileView;

  })(Backbone.View);

  exports["ProfileView"] = ProfileView;

}).call(this);


// coffeedev/views/main.coffee
(function() {
  var HomeView, MainView, exports, models, vp,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  exports = namespace("views.main");

  vp = require("views.profile");

  models = require("models");

  HomeView = (function(_super) {

    __extends(HomeView, _super);

    function HomeView() {
      return HomeView.__super__.constructor.apply(this, arguments);
    }

    HomeView.prototype.initialize = function() {
      var that;
      _.bindAll(this);
      that = this;
      return this.project = new models.Project();
    };

    return HomeView;

  })(Backbone.View);

  MainView = (function(_super) {

    __extends(MainView, _super);

    function MainView() {
      return MainView.__super__.constructor.apply(this, arguments);
    }

    MainView.prototype.initialize = function() {
      var that;
      _.bindAll(this);
      that = this;
      this.current_view = null;
      this.profile_view = new vp.ProfileView({
        el: this.el,
        template: $("#profile-view").html(),
        mainview: this
      });
      return this.options.logindata.on("change:loggedin", function(model, loggedin) {
        if (loggedin) {
          return that.on_login();
        } else {
          return that.on_logout();
        }
      });
    };

    MainView.prototype.on_login = function() {
      if (this.current_view === null) {
        return this.el.innerHTML = "";
      }
    };

    MainView.prototype.on_logout = function() {
      return this.login_required();
    };

    MainView.prototype.show_profile = function(key) {
      if (this.profile_view !== this.current_view || this.profile_view.user.get("key") !== key) {
        this.profile_view.set_user_and_render(key);
        return this.current_view = this.profile_view;
      }
    };

    MainView.prototype.render = function() {
      return this.current_view.render();
    };

    MainView.prototype.login_required = function() {
      return this.el.innerHTML = "<h2 class=\"center\">You need to sign in to continue!</h2>";
    };

    MainView.prototype.on_loading_error = function(xhr, status, error) {
      return this.http_error(xhr.status);
    };

    MainView.prototype.http_error = function(status) {
      switch (status) {
        case 403:
          return this.el.innerHTML = "<h2 class=\"center\">" + status + ": You're not allowed to access this.</h2>";
        case 404:
          return this.el.innerHTML = "<h2 class=\"center\">" + status + ": Requested document is not found.</h2>";
        case 405:
        case 400:
          return this.el.innerHTML = "<h2 class=\"center\">" + status + ": This request is invalid.</h2>";
        case 500:
          return this.el.innerHTML = "<h2 class=\"center\">" + status + ": The server encountered an error.</h2>";
      }
    };

    return MainView;

  })(Backbone.View);

  exports["MainView"] = MainView;

}).call(this);


// coffeedev/views/views.coffee
(function() {
  var exports;

  exports = namespace("views");

  require("views.navbar");

  require("views.messages");

  require("views.main");

  exports["NavBarView"] = views["navbar"]["NavBarView"];

  exports["FlashMessagesView"] = views["messages"]["FlashMessagesView"];

  exports["MainView"] = views["main"]["MainView"];

}).call(this);


// coffeedev//main.coffee
(function() {
  var AppRouter, models, views,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  views = require("views");

  models = require("models");

  _.templateSettings = {
    interpolate: /\{\[([\s\S]+?)\]\}/g,
    evaluate: /\{\@([\s\S]+?)\@\}/g
  };

  AppRouter = (function(_super) {

    __extends(AppRouter, _super);

    function AppRouter() {
      return AppRouter.__super__.constructor.apply(this, arguments);
    }

    AppRouter.prototype.routes = {
      "home": "home",
      "p/:key": "show_project",
      "profile/:key": "show_profile",
      "profile": "show_my_profile"
    };

    return AppRouter;

  })(Backbone.Router);

  $(document).ready(function(e) {
    var app_router, login_view, logindata, main_view, message_collection, message_view;
    $.ajaxSetup({
      dataType: "json"
    });
    message_collection = new models["MessageList"]();
    window.post_message = function(content, type) {
      var message;
      message = new models["Message"]({
        type: type,
        content: content
      });
      return message_collection.add(message);
    };
    logindata = new models["LoginData"]();
    message_view = new views["FlashMessagesView"]({
      el: $("div#messages"),
      message_collection: message_collection
    });
    main_view = new views["MainView"]({
      el: $("div#main"),
      message_collection: message_collection,
      logindata: logindata
    });
    login_view = new views["NavBarView"]({
      el: $("nav.top-bar"),
      message_collection: message_collection,
      logindata: logindata
    });
    app_router = new AppRouter();
    app_router.on("route:show_my_profile", function() {
      var current_user_key;
      current_user_key = window.current_user_key || logindata.get("current_user_key");
      if (current_user_key) {
        return main_view.show_profile(current_user_key);
      } else {
        return main_view.http_error(403);
      }
    });
    app_router.on("route:show_profile", function(key) {
      return main_view.show_profile(key);
    });
    return Backbone.history.start();
  });

}).call(this);


