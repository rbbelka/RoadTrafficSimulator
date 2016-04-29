'use strict'

require '../helpers'
_ = require 'underscore'
ControlSignals = require './control-signals'
Rect = require '../geom/rect'

class Intersection
  constructor: (@rect) ->
    @id = _.uniqueId 'intersection'
    @roads = []
    @inRoads = []
    @controlSignals = new ControlSignals this
    # intensity of generated traffic
    @lambda = 0

  @copy: (intersection) ->
    intersection.rect = Rect.copy intersection.rect
    result = Object.create Intersection::
    _.extend result, intersection
    result.roads = []
    result.inRoads = []
    result.controlSignals = ControlSignals.copy result.controlSignals, result
    result

  toJSON: ->
    obj =
      id: @id
      rect: @rect
      controlSignals: @controlSignals
      lambda: @lambda

  update: ->
    road.update() for road in @roads
    road.update() for road in @inRoads

module.exports = Intersection
