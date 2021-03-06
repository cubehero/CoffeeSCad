define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  marionette = require 'marionette'
  vent = require 'modules/core/vent'
  
  class CodeEditorRouter extends Backbone.Marionette.AppRouter
    #appRoutes: 
    #    "dummy:list"  : 'listDummies'
       
    constructor:(options)->
      super options
      @setController(options.controller)
      
    setController:(controller)=>
      @controller = controller
      for route, methodName of @appRoutes
        vent.bind(route, @controller[methodName])
            
  return CodeEditorRouter
