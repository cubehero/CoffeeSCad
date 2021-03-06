define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  marionette = require 'marionette'
  require 'bootstrap'
  require 'bootbox'
  
  vent = require './vent'
  mainMenu_template = require "text!./mainMenu2.tmpl"
  sF_template = require "text!./menuFiles.tmpl"
  
  class RecentFilesView extends Backbone.Marionette.ItemView
    template: sF_template
    tagName:  "li"
    
    onRender:()=>
      @$el.attr("id",@model.get("name"))
  
  class ExamplesView extends Backbone.Marionette.ItemView
    
    constructor:->
      #examples = require "modules/examples"
      #{Library,Project,ProjectFile} = require "modules/project"
    
    loadExample:(ev)=>
      #TOTAL HACK !! yuck
      index = ev.currentTarget.id
      project = new Project({name:examples[index].name})  
      mainPart = new ProjectFile
          name: "mainPart"
          ext: "coscad"
          content: examples[index].content    
      project.add mainPart
      
      ########VIEW UPDATES
      if @app.project.dirty
        bootbox.dialog "Project is unsaved, proceed anyway?", [
          label: "Ok"
          class: "btn-inverse"
          callback: =>
            @app.project = project
            @app.mainPart= mainPart
            @app.codeEditorView.switchModel @app.mainPart
            @app.glThreeView.switchModel @app.mainPart
            @app.mainMenuView.switchModel @app.project
        ,
          label: "Cancel"
          class: "btn-inverse"
          callback: ->
        ]
      else
        @app.project = project
        @app.mainPart= mainPart
        @app.codeEditorView.switchModel @app.mainPart
        @app.glThreeView.switchModel @app.mainPart
        @app.mainMenuView.switchModel @app.project
    
    onRender:()->
      @ui.examplesList.html("")
      for index,example of examples
        @ui.examplesList.append("<li id='#{index}' class='exampleProject'><a href=#> #{example.name}</a> </li>")
    
    
  class ExportersView extends Backbone.Marionette.CollectionView
    
  
  class AboutView 
  
  class MainMenuView extends Backbone.Marionette.Layout
    template: mainMenu_template
    regions:
      recentProjects:   "#recentProjects"
      examples:         "#examples"
      exporters:        "#exporters"
      
    events:
      "click .newProject":    ()->vent.trigger("project:new")
      "click .saveasProject": ()->vent.trigger("project:saveAs")
      "click .saveProject":   ()->vent.trigger("project:save")
      "click .loadProject":   ()->vent.trigger("project:load")
      "click .deleteProject": ()->vent.trigger("project:delete")
      
      "click .undo":          "onUndoClicked"
      "click .redo":          "onRedoClicked"
      
      "click .showEditor":    ()->vent.trigger("showEditor")
      
    constructor:(options)->
      super options
      @vent = vent
      
      @vent.on("file:selected", @onFileSelected)
      
      @on "file:new:mouseup" ,=>
        @vent.trigger("fileNewRequest", @)
      
      @on "csg:parserender:mouseup" ,=>
        if not  $('#updateBtn').hasClass "disabled"
          @vent.trigger("parseCsgRequest", @)
      @on "download:stl:mouseup" ,=>
        if not $('#exportStl').hasClass "disabled"
          @vent.trigger("downloadStlRequest", @) 
        
      @vent.bind "file:undoAvailable", ->
        $('#undoBtn').removeClass("disabled")
      @vent.bind "file:redoAvailable", ->
        $('#redoBtn').removeClass("disabled")
      @vent.bind "file:undoUnAvailable", ->
        $('#undoBtn').addClass("disabled")
      @vent.bind "file:redoUnAvailable", ->
        $('#redoBtn').addClass("disabled")
        
      @vent.bind "clearUndoRedo", ->
        $('#undoBtn').addClass("disabled")
        $('#redoBtn').addClass("disabled")
      @vent.bind "modelChanged", ->
        $('#updateBtn').removeClass("disabled")
        $('#exportStl').addClass("disabled")
      @vent.bind "parseCsgDone", ->
        $('#updateBtn').addClass("disabled")
        $('#exportStl').removeClass("disabled") 
      
     onFileSelected:(model)=>
       $('#undoBtn').addClass("disabled")
       $('#redoBtn').addClass("disabled")
       
     onUndoClicked:->
      console.log $('#undoBtn')
      if not  $('#undoBtn').hasClass "disabled"
        console.log "triggering undo Request"
        @vent.trigger("file:undoRequest")
        
     onRedoClicked:->
      if not  $('#redoBtn').hasClass "disabled"
        @vent.trigger("file:redoRequest")
     
     onRender:=>
       $('#undoBtn').addClass("disabled")
       $('#redoBtn').addClass("disabled")
        
       
  
  
  class MainMenuView_old extends marionette.CompositeView
    template: mainMenu_template
    tagName:  "ul"
    itemView: RecentFilesView
    itemViewContainer: "#recentFilesList"
    ui:
      dirtyStar:    "#dirtyStar"
      examplesList: "#examplesList"

    triggers: 
      "mouseup .newFile":     "file:new:mouseup"
      "mouseup .saveFile":    "file:save:mouseup"
      "mouseup .saveFileAs":  "file:saveas:mouseup"
      "mouseup .loadFile":    "file:load:mouseup"
      "mouseup .newProject":  "project:new:mouseup"
      "mouseup .settings":    "settings:mouseup"
      "mouseup .undo":        "file:undo:mouseup"
      "mouseup .redo":        "file:redo:mouseup"
      "mouseup .parseCSG"  :  "csg:parserender:mouseup"
      "mouseup .downloadStl" :"download:stl:mouseup"
      
    
     events: 
      "mouseup .loadFileDirect":    "requestFileLoad"
      "mouseup .showEditor":        "showEditor"
      "mouseup #aboutBtn":          "showAbout"
      "mouseup .exampleProject":     "loadExample"
      
     templateHelpers:
       dirtyStar: ()=>
         if @model?
          if @model.dirty then return "*" else return ""
         else
          return ""
    
    requestFileLoad:(ev)=>
      fileName = $(ev.currentTarget).html()
      @vent.trigger("fileLoadRequest", fileName)
    
    showEditor:(ev)=>
      @vent.trigger("editorShowRequest")
      
    showAbout:(ev)=>
      bootbox.dialog """<b>Coffeescad v0.1</b> (experimental)<br/><br/>
      Licenced under the MIT Licence<br/>
      @2012 by Mark 'kaosat-dev' Moissette
      
      """, [
          label: "Ok"
          class: "btn-inverse"
        ],
        "backdrop" : false
        "keyboard":   true
        "animate":false
      
    constructor:(options)->
      super options
      @vent = vent
      @settings = null
      
      #@settings = @app.settings.byName("General")
      #filtered = @collection.first(@settings.get("maxRecentFilesDisplay"))
      #@originalCollection = @collection
      #@collection = new Backbone.Collection(filtered)
      
      
      @bindTo(@model, "change", @modelChanged)
      @bindTo(@model, "allSaved", @modelSaved)
      @bindTo(@settings, "change", @settingsChanged)
      
      @on "file:new:mouseup" ,=>
        @vent.trigger("fileNewRequest", @)
      @on "file:undo:mouseup" ,=>
        if not  $('#undoBtn').hasClass "disabled"
          @vent.trigger("undoRequest", @)
      @on "file:redo:mouseup" ,=>
        if not  $('#redoBtn').hasClass "disabled"
          @vent.trigger("redoRequest", @)
      @on "csg:parserender:mouseup" ,=>
        if not  $('#updateBtn').hasClass "disabled"
          @vent.trigger("parseCsgRequest", @)
      @on "download:stl:mouseup" ,=>
        if not $('#exportStl').hasClass "disabled"
          @vent.trigger("downloadStlRequest", @) 
        
      @vent.bind "undoAvailable", ->
        $('#undoBtn').removeClass("disabled")
      @vent.bind "redoAvailable", ->
        $('#redoBtn').removeClass("disabled")
      @vent.bind "undoUnAvailable", ->
        $('#undoBtn').addClass("disabled")
      @vent.bind "redoUnAvailable", ->
        $('#redoBtn').addClass("disabled")
      @vent.bind "clearUndoRedo", ->
        $('#undoBtn').addClass("disabled")
        $('#redoBtn').addClass("disabled")
      @vent.bind "modelChanged", ->
        $('#updateBtn').removeClass("disabled")
        $('#exportStl').addClass("disabled")
      @vent.bind "parseCsgDone", ->
        $('#updateBtn').addClass("disabled")
        $('#exportStl').removeClass("disabled")
      
      @vent.bind "stlGenDone", (blob)=>
        tmpLnk = $("#exportStlLink")
        fileName = @app.project.get("name")
        tmpLnk.prop("download", "#{fileName}.stl")
        tmpLnk.prop("href", blob)
        
    switchModel:(newModel)->
      #replace current model with a new one
      #@unbindFrom(@model) or @unbindAll() ?
      @model = newModel
      @bindTo(@model, "dirtied", @modelChanged)
      @bindTo(@model, "allSaved", @modelSaved)
      @render()
      
    modelChanged: (model, value)=>
      @ui.dirtyStar.text "*"
     
    modelSaved: (model)=>
      @ui.dirtyStar.text ""
      
    settingsChanged:(settings, value)=> 
      for key, val of @settings.changedAttributes()
        switch key
          when "maxRecentFilesDisplay"
            filtered = @originalCollection.first(@settings.get("maxRecentFilesDisplay"))
            @collection = new Backbone.Collection(filtered)
            @render()
    
      
  return MainMenuView