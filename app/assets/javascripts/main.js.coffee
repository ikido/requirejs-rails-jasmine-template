# XXX: Define could be require?
# Unfortunately, with requirejs I could not get the js files to load automatically
# as expect from assets folder. So I just created an intermediate which is called.
# Eventually, maybe we want to add, like:
# https://github.com/backbone-boilerplate/backbone-boilerplate/blob/master/app/app.js

# Still not convinced if I need to load up all the module
define ['app'
        ,'backbone.layoutmanager'], (App) ->

  App.Models.MainPage = Backbone.Model.extend({})

  App.Views.ContentView = Backbone.View.extend(
    manage: true
    template: "#main-view"

    serialize: ->
      console.log "Serialize"
      #@model.toJSON()
      name: "psykidellic"
  )

  start: ->
    console.log "Never called"

    $ ->
      #XXX: Another way to setup the module would be to new User or new User.views
      #.list but this works for now.
      console.log "debugger"

      App.Models.mainPage = new App.Models.MainPage(name: "Test title")
      App.Views.mainLayout = new App.Views.ContentView(model: App.Models.mainPage)
      $(".container").empty().append App.Views.mainLayout.el

      App.Views.mainLayout.render()

      #Backbone.history.start pushState: true

      console.log "Started"
