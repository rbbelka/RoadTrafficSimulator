#!/usr/bin/env coffee
'use strict'

{random} = Math
require './helpers'
World = require './model/world'
_ = require 'underscore'
settings = require './settings'
fs = require 'fs'


avgInstantSpeed = (setupCallback) ->
  world = new World()
  map = fs.readFileSync './experiments/map2l.json', {encoding: 'utf8'}
  world.load map
#  world.generateMap()
  world.carsNumber = 400
  setupCallback?(world)
  results = []
  for i in [0..1000]
    world.onTick 0.2
    results.push world.instantSpeed
  (results.reduce (a, b) -> a + b) / results.length

avgCarSpeed = (setupCallback) ->
  world = new World()
  map = fs.readFileSync './experiments/map2l.json', {encoding: 'utf8'}
  world.load map
#  world.generateMap()
  world.carsNumber = 100
  setupCallback?(world)
  for i in [0..3000]
    world.onTick 0.2
  world.avgCarsSpeed

avgSpeed = (setupCallback) ->
  world = new World()
#  world.generateMap8()
  map = fs.readFileSync '../experiments/map2.json', {encoding: 'utf8'}
  world.load map
  world.carsNumber = 50
  setupCallback?(world)
  results = []
  for i in [0..3000]
    world.onTick 0.2
    results.push world.instantSpeg  ed
  return [(results.reduce (a, b) -> a + b) / results.length, world.avgCarsSpeed]

avgSpeed0 = () ->
  world = new World()
  #  world.generateMap8()
  map = fs.readFileSync '../experiments/map2.json', {encoding: 'utf8'}
  world.load map
  world.carsNumber = 50
  results = []
  for i in [0..2000]
    world.onTick 0.2
    results.push world.instantSpeed
  return world.avgCarsSpeed

getParams = (world) ->
  params = (i.controlSignals.flipMultiplier for id, i of world.intersections.all())
  # console.log JSON.stringify(params)
  params

settings.lightsFlipInterval = 200

experiment0 = () ->
  out = fs.createWriteStream '../experiments/0.data'
  result = avgSpeed0()
  console.log result
  out.write(result + ' ');

experiment0()



experiment = () ->
  out = fs.createWriteStream '../experiments/0.data'
  out.write '"flipMult" "avgInstantSpeed" "avgCarSpeed"\n'
  x_max1 = -1
  result_max1 = -1
  x_max2 = -1
  result_max2 = -1
  for it in [0..100]
    x = random()
    result = avgSpeed (world) ->
      i.controlSignals.flipMultiplier = x for id, i of world.intersections.all()
      getParams world
    console.log it
    out.write('"'+ (it+1) + '" ' + ((0.1 + 0.05 * x) * settings.lightsFlipInterval) + ' ' +  result[0] + ' ' + result[1] + '\n')
    if result[0] > result_max1
      x_max1 = x
      result_max1 = result[0]
    if result[1] > result_max2
      x_max2 = x
      result_max2 = result[1]
  out.write('max1: ' + ((0.1 + 0.05 * x_max1 ) * settings.lightsFlipInterval) + ' ' +  result_max1 + ' ' + 0 + '\n')
  out.write('max2: ' + ((0.1 + 0.05 * x_max2 ) * settings.lightsFlipInterval) + ' ' + 0 + ' ' +  result_max2 + '\n')


#experiment()


experiment4 = () ->
  out = fs.createWriteStream './experiments/avgInstance/flip50.data'
  out.write '"flipMult" "avgSpeed"\n'
  x_max = -1
  result_max = -1
  for it in [0..60]
    x = random()
    result = avgInstantSpeed (world) ->
      i.controlSignals.flipMultiplier = x for id, i of world.intersections.all()
      getParams world
    out.write('"'+ (it+1) + '" ' + ((0.1 + 0.05 * x) * settings.lightsFlipInterval) + ' ' +  result + '\n')
    if result > result_max
      x_max = x
      result_max = result
  out.write('max: ' + ((0.1 + 0.05 * x_max) * settings.lightsFlipInterval) + ' ' +  result_max + '\n')


experiment5 = () ->
  out = fs.createWriteStream './experiments/avgCar/flip400test5.data'
  out.write '"flipMult" "avgSpeed"\n'
  x_max = -1
  result_max = -1
  for it in [0..100]
    x = random()
    result = avgCarSpeed (world) ->
      i.controlSignals.flipMultiplier = x for id, i of world.intersections.all()
      getParams world
    out.write('"'+ (it+1) + '" ' + ( x * settings.lightsFlipInterval) + ' ' +  result + '\n')
    if result > result_max
      x_max = x
      result_max = result
  out.write('max: ' + ( x_max * settings.lightsFlipInterval) + ' ' +  result_max + '\n')

#experiment4()
#experiment5()
