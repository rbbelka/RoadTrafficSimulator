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

  @property 'avgCarsSpeed',
    get: ->
      sumRemoved = _.reduce @carsAvgSpeed, ((a, b) -> a + b), 0
      stayed = _.map @cars.all(), (car) -> car.avgSpeed
      sumStayed = _.reduce stayed, ((a, b) -> a + b), 0
      return 0 if (@carsAvgSpeed.length + stayed.length) is 0
      return (sumRemoved + sumStayed) / (@carsAvgSpeed.length + stayed.length)

  set: (obj) ->
    obj ?= {}
    @intersections = new Pool Intersection, obj.intersections
    @roads = new Pool Road, obj.roads
    @cars = new Pool Car, obj.cars
    @carsNumber = 0
    @time = 0
    @carsAvgSpeed = []

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
    for id, road of data.roads
      road = Road.copy road
      road.source = @getIntersection road.source
      road.target = @getIntersection road.target
      @addRoad road


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

  generateMap8: ->
    @clear()
    coords = [[-3,0],[-1,0],[1,0],[3,0],[-1,-2],[-1,2],[1,-2],[1,2]]
    map = {}
    gridSize = settings.gridSize
    step = 5 * gridSize
    @carsNumber = 100
    for item in coords
      x = item[0]
      y = item[1]
      unless map[[x, y]]?
        rect = new Rect step * x, step * y, gridSize, gridSize
        intersection = new Intersection rect
        @addIntersection map[[x, y]] = intersection
    @addTwoNewRoads 0, 1, map, coords
    @addTwoNewRoads 2, 1, map, coords
    @addTwoNewRoads 2, 3, map, coords
    @addTwoNewRoads 4, 1, map, coords
    @addTwoNewRoads 5, 1, map, coords
    @addTwoNewRoads 6, 2, map, coords
    @addTwoNewRoads 7, 2, map, coords
    null

  generateMap12: ->
    @clear()
    coords = [[-3,0],[-1,0],[1,0],[3,0],[-3,2],[-1,2],[1,2],[3,2],[-1,4],[1,4],[-1,-2],[-1,2]]
    map = {}
    gridSize = settings.gridSize
    step = 5 * gridSize
    @carsNumber = 100
    for item in coords
      x = item[0]
      y = item[1]
      unless map[[x, y]]?
        rect = new Rect step * x, step * y, gridSize, gridSize
        intersection = new Intersection rect
        @addIntersection map[[x, y]] = intersection
    @addTwoNewRoads 0, 1, map, coords
    @addTwoNewRoads 1, 2, map, coords
    @addTwoNewRoads 2, 3, map, coords
    @addTwoNewRoads 4, 5, map, coords
    @addTwoNewRoads 5, 6, map, coords
    @addTwoNewRoads 6, 7, map, coords
    @addTwoNewRoads 10, 5, map, coords
    @addTwoNewRoads 5, 1, map, coords
    @addTwoNewRoads 1, 8, map, coords
    @addTwoNewRoads 6, 11, map, coords
    @addTwoNewRoads 6, 2, map, coords
    @addTwoNewRoads 2, 9, map, coords
    null

  clear: ->
    @set {}

  onTick: (delta) =>
    throw Error 'delta > 1' if delta > 1
    @time += delta
    @refreshCars()
    for id, intersection of @intersections.all()
      intersection.controlSignals.onTick delta
    for id, car of @cars.all()
      car.move delta
      car.avgSpeed = car.speed    #recount avg_speed
      @removeCar car unless car.alive

  refreshCars: ->
    @addRandomCar() if @cars.length < @carsNumber
    @removeRandomCar() if @cars.length > @carsNumber

  addTwoNewRoads: (from, to, map, coords) ->
    @addRoad new Road map[coords[from]], map[coords[to]]
    @addRoad new Road map[coords[to]], map[coords[from]]
    null

  addRoad: (road) ->
    @roads.put road
    road.source.roads.push road
    road.target.inRoads.push road
    road.update()

  getRoad: (id) ->
    @roads.get id

  addCar: (car) ->
    @cars.put car

  getCar: (id) ->
    @cars.get(id)

  removeCar: (car) ->
    @carsAvgSpeed.push car.avgSpeed
#    console.log car.avgSpeed
    @cars.pop car

  addIntersection: (intersection) ->
    @intersections.put intersection

  getIntersection: (id) ->
    @intersections.get id

  addRandomCar: ->
    road = _.sample @roads.all()
    if road?
      lane = _.sample road.lanes
      @addCar new Car lane if lane?

  removeRandomCar: ->
    car = _.sample @cars.all()
    if car?
      @removeCar car

module.exports = World

