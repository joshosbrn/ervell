Backbone = require 'backbone'
template = -> require('./index.jade') arguments...

module.exports = class CancelPlanView extends Backbone.View
  className: 'cancel-plan'

  events:
    'click .js-cancel': 'cancelPlan'

  cancelPlan: (e) ->
    e.preventDefault()

    label = ($target = $(e.currentTarget)).text()

    $target.text 'Canceling'

    @model.related().subscription.destroy()
      .then =>
        location.reload()

        $target.text 'Canceled'

      , (error) =>
        $target.text label

        @els.errors
          .show()
          .text error.message

        setTimeout () =>
          @els.errors
            .empty()
            .hide()
        , 2000

  postRender: ->
    @els =
      errors: @$('.js-form-errors')

  render: ->
    @$el.html template()
    @postRender()
    this
