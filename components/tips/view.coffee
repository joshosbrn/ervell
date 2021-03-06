Backbone = require 'backbone'
Dismisser = require '../has_seen/dismisser.coffee'
analytics = require '../../lib/analytics.coffee'
Promise = require 'bluebird-q'

module.exports = class TipView extends Backbone.View
  events:
    'click': 'onClick'
    'click .js-close' : 'close'

  initialize: ({ @user }) ->
    @dismisser = new Dismisser
      key: @model.id
      limit: 1

  onClick: (e) ->
    e.preventDefault()
    e.stopPropagation()

    @collection.remove @model

    switch @model.get 'trigger'
      when 'new:channel'
        # Opens the new channel dialog
        $dropdown = $('.js-triggerable-channel-create')
        $dropdown.addClass hoverClass = 'DropdownHover--hover'

        # Closes it when the body is clicked
        $('body').one 'click', (e) ->
          $dropdown.removeClass hoverClass

    @maybeDisable()
      .finally =>
        @maybeRedirect()
        @remove()

  maybeDisable: ->
    if @collection.length
      Promise.resolve()
    else
      Promise @user.save(show_tour: false)

  maybeRedirect: ->
    if @model.has 'href'
      window.location = @model.get 'href'

  close: (e) ->
    e.preventDefault()
    e.stopImmediatePropagation()

    @collection.remove @model

    @maybeDisable()
      .finally =>
        @remove()

  remove: ->
    @dismisser.dismiss()
    
    analytics.track.click 'Block tip closed', id: @model.id

    super

