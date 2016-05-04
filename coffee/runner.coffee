#!/usr/bin/env coffee
'use strict'

require './helpers'
World = require './model/world'
_ = require 'underscore'
settings = require './settings'
fs = require 'fs'

measureAverageSpeed = (setupCallback) ->
  world = new World()
  map = fs.readFileSync './experiments/map.json', {encoding: 'utf8'}
  # console.log map
  # world.generateMap()
  world.load map
  #world.carsNumber = 50
  setupCallback?(world)
  results = []
  for i in [0..10000]
    world.onTick 0.2
    # console.log world.instantSpeed
    results.push world.instantSpeed
  (results.reduce (a, b) -> a + b) / results.length

measureAverageWaitingTime = () ->
  world = new World()
  map = fs.readFileSync '../experiments/map.copy.json', {encoding: 'utf8'}
  world.load map
  for i in [0..10000]
    world.onTick 0.1
  avg = 0.0
  cnt = 0
  for id, t of world.intersectionAvgWaitingTime
    if t > 0
      avg = avg + t
      cnt = cnt + 1
  avg = avg / cnt
  avg

generateData = () ->
  t = []
  for i in _.range 1000000
    t.push (_.sample (_.range 1, 31)) / 10
  t

generateConfig = (world, t) ->
  # generate configuration for working controllers
  for intersect in world.workingIntersections
    intersect.controlSignals.delayMultiplier = _.sample(t, 4)

generateTrainingSet = () ->
  out = fs.createWriteStream './experiments/0.data'

  t = generateData()
  map = fs.readFileSync './experiments/map.json', {encoding: 'utf8'}

  for i in _.range(160)
    console.log( i )
    world = new World()
    world.load map
    generateConfig(world, t)
    for intersect in world.workingIntersections
      out.write(intersect.controlSignals.delayMultiplier + ', ')
      console.log intersect.controlSignals.delayMultiplier
    results = []
    for j in [0..10000]
      world.onTick 0.1
    avg = 0.0
    cnt = 0
    for id, time of world.intersectionAvgWaitingTime
      if time > 0
        avg = avg + time
        cnt = cnt + 1
    avg = avg / cnt
    out.write(avg + '\n')
    console.log(avg)
    results.push avg



getParams = (world) ->
  params = (i.controlSignals.flipMultiplier for id, i of world.intersections.all())
  # console.log JSON.stringify(params)
  params

settings.lightsFlipInterval = 160

experiment0 = () ->
  out = fs.createWriteStream '../experiments/0.data'
  result = measureAverageWaitingTime()
  console.log result
  out.write(result + ' ');

experiment1 = () ->
  out = fs.createWriteStream './experiments/1.data'
  out.write 'multiplier avg_speed\n'
  for multiplier in [0.0001, 0.01, 0.02, 0.05, 0.1, 0.25, 0.5, 0.75, 1, 2, 3, 4, 5]
    do (multiplier) ->
      result = measureAverageSpeed (world) ->
        i.controlSignals.flipMultiplier = multiplier for id, i of world.intersections.all()
        getParams world
      out.write(multiplier + ' ' +  result + '\n')

experiment2 = () ->
  out = fs.createWriteStream './experiments/2.data'
  out.write 'it avg_speed\n'
  for it in [0..9]
    result = measureAverageSpeed (world) ->
      i.controlSignals.flipMultiplier = Math.random() for id, i of world.intersections.all()
      getParams world
    out.write(it + ' ' +  result + '\n')

experiment3 = () ->
  out = fs.createWriteStream './experiments/3.data'
  out.write 'it avg_speed\n'
  for it in [0..10]
    result = measureAverageSpeed (world) ->
      i.controlSignals.flipMultiplier = 1 for id, i of world.intersections.all()
      i.controlSignals.phaseOffset = 0
      getParams world
    out.write(it + ' ' +  result + '\n')

# experiment1()
# experiment2()
# experiment3()
experiment0()
# generateTrainingSet()
