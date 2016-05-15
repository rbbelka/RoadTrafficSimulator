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
fs = require 'fs'

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
    #
    @carsAvgSpeed = []
    #
    @goodIntersections = []
    @workingIntersections = []
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
    # sampling from discrete distribution
    @prob = []
    @F = []


  save: ->
    #for id, i of @intersections.all()
    #  i.controlSignals.delayMultiplier = [0.5,0.5,0.5,0.5]
    #  i.lambda = 0
    #for i in @goodIntersections
    #  i.lambda = _.sample (_.range 10)
    data = _.extend {}, this
    delete data.cars
    localStorage.world = JSON.stringify data
    #console.log(JSON.stringify data)
    $.post 'http://localhost:3000/upload', { 'data': JSON.stringify data }

  load: (data) ->
    if data 
      @defaultLoad(JSON.parse data)
      #console.log('1')
    else 
      $.ajax({
        url: 'http://localhost:3000/',
        type: 'get',
        async: false,
        dataType:"json",
        crossDomain:true,
        success: (result) =>
          @defaultLoad(result)
        })
      #console.log('2')

  defaultLoad: (data) ->
    #data = data or localStorage.world
    #data = data and JSON.parse data
    #return unless data?
    @clear()
    # @carsNumber = data.carsNumber or 0

    for id, intersection of data.intersections
      #@addIntersection Intersection.copy intersection
      @intersections.put Intersection.copy intersection
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
    @initStat()

  initStat: ->
    @goodIntersections = _.filter( @intersections.all() , (i) -> i.roads.length == 1 )
    @workingIntersections = _.filter( @intersections.all() , (i) -> i.roads.length != 1 )
    @carsNumber = 0
    for id, i of @intersections.all()
      #console.log(i.lambda)
      @carsNumber = @carsNumber + i.lambda

    #console.log(@carsNumber)
    @prob = _.map @goodIntersections, (i) -> [i.lambda, i.id]
    @prob = _.sortBy @prob, (p) -> p[0]
    @F = []
    if @goodIntersections.length > 0
      @F[0] = @prob[0][0]
      for i in _.range(1, @goodIntersections.length)
        @F[i] = @F[i-1] + @prob[i][0]
      #for i of _.range(@goodIntersections.length)
      #  console.log(@prob[i][0] + ' ' + @prob[i][1] + ' ' + @F[i])

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
    @refreshStat(delta)
    @refreshCars()
    for id, intersection of @intersections.all()
      intersection.controlSignals.onTick delta
    for id, car of @cars.all()
      car.move delta
      car.avgSpeed = car.speed    #recount avg_speed
      @removeCar car unless car.alive
    #
    #console.log(@time + ' ' + delta)
    #for id, t of @intersectionAvgWaitingTime
    #  if t > 0
    #    console.log(id + ' ' + t)
    #console.log (' ')

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
    @carsWaitTime[car.id] = 0
    @carStoped[car.id] = false
    @carsCurTarget[car.id] = car.trajectory.nextIntersection.id

  getCar: (id) ->
    @cars.get(id)

  removeCar: (car) ->
    @carsAvgSpeed.push car.avgSpeed
#    console.log car.avgSpeed
    @cars.pop car

  addIntersection: (intersection) ->
    @intersections.put intersection
    #
    @intersectionTotalNumberOfCars[intersection.id] = 0.0
    @intersectionAvgWaitingTime[intersection.id] = 0.0
    @initStat()


  getIntersection: (id) ->
    @intersections.get id

  addRandomCar: ->
    # road = _.sample @roads.all()
    x = _.sample _.range(@carsNumber + 1)
    k = _.sortedIndex @F, x
    good_intersection = @getIntersection(@prob[k][1])
    #good_intersection = _.sample( @goodIntersections )

    road = _.sample( good_intersection.roads )
    if road?
      lane = _.sample road.lanes
      @addCar new Car lane if lane?

  removeRandomCar: ->
    car = _.sample @cars.all()
    if car?
      @removeCar car

module.exports = World

