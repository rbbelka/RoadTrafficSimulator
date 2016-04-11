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
#  map = fs.readFileSync './experiments/map2lights.json', {encoding: 'utf8'}
#  world.load map
  world.generateMap8()
  world.carsNumber = 100
  setupCallback?(world)
  results = []
  for i in [0..1000]
    world.onTick 0.2
    results.push world.instantSpeed
  (results.reduce (a, b) -> a + b) / results.length

avgCarSpeed = (setupCallback) ->
  world = new World()
  world.generateMap8()
  world.carsNumber = 100
  setupCallback?(world)
  results = []
  for i in [0..1000]
    world.onTick 0.2
    results.push world.instantSpeed
  (results.reduce (a, b) -> a + b) / results.length

getParams = (world) ->
  params = (i.controlSignals.flipMultiplier for id, i of world.intersections.all())
  # console.log JSON.stringify(params)
  params

settings.lightsFlipInterval = 50

experiment4 = () ->
  out = fs.createWriteStream './experiments/flip50.data'
  out.write '"flipMult" "avg_speed"\n'
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

experiment4()