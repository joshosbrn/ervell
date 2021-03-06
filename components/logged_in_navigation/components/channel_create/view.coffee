Promise = require 'bluebird-q'
Backbone = require 'backbone'
{ track, en } = require '../../../../lib/analytics.coffee'
template = -> require('./index.jade') arguments...

module.exports = class ChannelCreateView extends Backbone.View
  events:
    'mouseover': 'focus'
    'keyup .js-title': 'onKeyup'
    'input .js-title': 'title'
    'click .js-status': 'status'
    'click .js-create': 'create'
    'input': 'onInteraction'
    'click': 'onInteraction'

  initialize: ({ @user }) ->
    @listenTo @model, 'change', @render

  onKeyup: (e) ->
    return unless e.keyCode is 13
    @create e

  onInteraction: (e) ->
    e.stopPropagation()
    @trigger 'persist'

  focus: ->
    @dom.title.focus()

  title: ->
    @model.set 'title', @dom.title.val(), silent: true

  status: (e) ->
    e.preventDefault()

    status = $(e.currentTarget).data 'value'
    @model.set 'status', status

  create: (e) ->
    e.preventDefault()

    return unless @model.has('title')

    @dom.create.text 'Creating...'

    Promise(@model.save())
      .then =>
        @dom.create.text 'Redirecting...'

        window.location.href =
          "/#{@model.get('user').slug}/#{@model.get('slug')}"

      .catch =>
        @dom.create.text 'Error'

    track.submit en.CREATE_CHANNEL

  render: ->
    @$el.html template
      user: @user
      channel: @model

    @dom =
      title: @$('.js-title')
      create: @$('.js-create')

    @focus()

    this
