# Underscrore template does not go well with HAML format.
# Use mustache one. Suggested on Google Groups @ HAML.

define ['underscore', 'backbone'], (_, Backbone) ->
  _.templateSettings =
    interpolate: /\{\{\=(.+?)\}\}/g
    evaluate: /\{\{(.+?)\}\}/g

  Views: {}
  Models: {}
