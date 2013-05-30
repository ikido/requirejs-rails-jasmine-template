require.config shim:
  underscore:
    exports: "_"

  backbone:
    deps: ["underscore", "jquery"]
    exports: "Backbone"

  "backbone.layoutmanager": ["backbone"]

require ['jquery', 'backbone', 'main'], ($, Backbone, Main) ->

  #XXX: This coule be badly named modules but could not figure out creating circular dependency
  console.log "Starting"
  #between app and router without a third module so I am just going to use it.
  Main.start()


