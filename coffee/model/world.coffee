'use strict'

{random} = Math
require '../helpers'
_ = require 'underscore'
Car = require './car'
Intersection = require './intersection'
Road = require './road'
Pool = require './pool'
Rect = require '../geom/rect'
settings = require '../settings'

class World
  constructor: ->
    @set {}

  @property 'instantSpeed',
    get: ->
      speeds = _.map @cars.all(), (car) -> car.speed
      return 0 if speeds.length is 0
      return (_.reduce speeds, (a, b) -> a + b) / speeds.length

  set: (obj) ->
    obj ?= {}
    @intersections = new Pool Intersection, obj.intersections
    @roads = new Pool Road, obj.roads
    @cars = new Pool Car, obj.cars
    @carsNumber = 0
    @time = 0
    # arrays for some statistics
    @intersectionsStat = {}
    @intersectionTotalNumberOfCars = {} # total number of cars which passed through intersection
    @intersectionAvgWaitingTime = {}    # average waiting time at intersection
    @carsWaitTime = {}                  # current waiting time of car at specific intersection
    @carsCurTarget = {}                 # target-intersection
    @carStoped = {}                     # true - if car currently waiting at intersection
    # initial statistics
    for id, car of @cars.all()
      @carsWaitTime[id] = 0.0
      @carsCurTarget[id] = car.trajectory.nextIntersection.id
      @carStoped[id] = false
    for id, i of @intersections.all()
      @intersectionTotalNumberOfCars[id] = 0.0
      @intersectionAvgWaitingTime[id] = 0.0

  save: ->
    data = _.extend {}, this
    delete data.cars
    localStorage.world = JSON.stringify data

  load: (data) ->
    data = data or localStorage.world
    data = data and JSON.parse data
    return unless data?
    @clear()
    @carsNumber = data.carsNumber or 0
    for id, intersection of data.intersections
      @addIntersection Intersection.copy intersection
      #console.log(intersection.id)
    for id, road of data.roads
      road = Road.copy road
      road.source = @getIntersection road.source
      road.target = @getIntersection road.target
      @addRoad road
    # initial statistics
    for id, i of @intersections.all()
      @intersectionTotalNumberOfCars[id] = 0.0
      @intersectionAvgWaitingTime[id] = 0.0

  generateMap: (minX = -2, maxX = 2, minY = -2, maxY = 2) ->
    @clear()
    intersectionsNumber = (0.8 * (maxX - minX + 1) * (maxY - minY + 1)) | 0
    map = {}
    gridSize = settings.gridSize
    step = 5 * gridSize
    @carsNumber = 100
    while intersectionsNumber > 0
      x = _.random minX, maxX
      y = _.random minY, maxY
      unless map[[x, y]]?
        rect = new Rect step * x, step * y, gridSize, gridSize
        intersection = new Intersection rect
        @addIntersection map[[x, y]] = intersection
        intersectionsNumber -= 1
    for x in [minX..maxX]
      previous = null
      for y in [minY..maxY]
        intersection = map[[x, y]]
        if intersection?
          if random() < 0.9
            @addRoad new Road intersection, previous if previous?
            @addRoad new Road previous, intersection if previous?
          previous = intersection
    for y in [minY..maxY]
      previous = null
      for x in [minX..maxX]
        intersection = map[[x, y]]
        if intersection?
          if random() < 0.9
            @addRoad new Road intersection, previous if previous?
            @addRoad new Road previous, intersection if previous?
          previous = intersection
    null


  clear: ->
    @set {}

  onTick: (delta) =>
    throw Error 'delta > 1' if delta > 1
    @time += delta
    @refreshStat(delta)
    @refreshCars()
    for id, intersection of @intersections.all()
      intersection.controlSignals.onTick delta
    for id, car of @cars.all()
      car.move delta
      @removeCar car unless car.alive

  refreshStat: (delta) ->
    for id, intersection of @intersections.all()
      @intersectionsStat[id] = 0
    for id, car of @cars.all()
      if car.trajectory.isChangingLanes == false
        newTarget = car.trajectory.nextIntersection.id
        oldTarget = @carsCurTarget[id]

        @intersectionsStat[newTarget] += 1

        s = Math.round(car.speed*10)/10
        # is s = 0 => car has stopped
        if s == 0
          @carStoped[id] = true
        # car is waiting in lane before intersection
        if @carStoped[id] == true
          @carsWaitTime[id] += delta

        if oldTarget != newTarget
          @intersectionTotalNumberOfCars[oldTarget] += 1.0
          n = @intersectionTotalNumberOfCars[oldTarget]
          @intersectionAvgWaitingTime[oldTarget] = 1.0 / n * (@carsWaitTime[id] + (n-1) * @intersectionAvgWaitingTime[oldTarget])

          @carsWaitTime[id] = 0.0
          @carsCurTarget[id] = newTarget
          @carStoped[id] = false


  refreshCars: ->
    @addRandomCar() if @cars.length < @carsNumber
    @removeRandomCar() if @cars.length > @carsNumber

  addRoad: (road) ->
    @roads.put road
    road.source.roads.push road
    road.target.inRoads.push road
    road.update()

  getRoad: (id) ->
    @roads.get id

  addCar: (car) ->
    @cars.put car
    @carsWaitTime[car.id] = 0
    @carStoped[car.id] = false
    @carsCurTarget[car.id] = car.trajectory.nextIntersection.id

  getCar: (id) ->
    @cars.get(id)

  removeCar: (car) ->
    @cars.pop car

  addIntersection: (intersection) ->
    @intersections.put intersection

  getIntersection: (id) ->
    @intersections.get id

  addRandomCar: ->
    # road = _.sample @roads.all()
    good_intersection = _.sample( _.filter( @intersections.all() , (i) -> i.roads.length == 1 ) )

    road = _.sample( good_intersection.roads )
    if road?
      lane = _.sample road.lanes
      @addCar new Car lane if lane?

  removeRandomCar: ->
    car = _.sample @cars.all()
    if car?
      @removeCar car

module.exports = World
