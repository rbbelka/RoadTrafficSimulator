#!/usr/bin/env coffee
'use strict'

{random} = Math
require './helpers'
World = require './model/world'
_ = require 'underscore'
settings = require './settings'
fs = require 'fs'

avgSpeed = (delays) ->
  world = new World()
  #  world.generateMap8()
  map = fs.readFileSync './experiments/map4.json', {encoding: 'utf8'}
  world.load map
  wi = _.filter( world.intersections.all() , (i) -> i.roads.length > 1 )
  i = 0
  for int in wi
    int.controlSignals.flipMultiplier = delays[i]
    i += 1
  for i in [0..3000]
    world.onTick 0.2
  return world.avgCarsSpeed

avgSpeed0 = () ->
  world = new World()
  map = fs.readFileSync '../experiments/map4.json', {encoding: 'utf8'}
  world.load map
  for i in [0..3000]
    world.onTick 0.2
  return world.avgCarsSpeed

getParams = (world) ->
  params = (i.controlSignals.delayMultiplier for id, i of world.intersections.all())
  # console.log JSON.stringify(params)
  params

experiment0 = () ->
  out = fs.createWriteStream '../experiments/0.data'
  result = avgSpeed0()
  console.log result
  out.write(result + ' ');

experiment0()


experiment = () ->
  out = fs.createWriteStream './experiments/rand/3.data'
  delays_max = []
  result_max = -1
  delays = [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]
  for it in [0..60]
    for i in [0..15]
      delays[i] = 3 * random()
    result = avgSpeed (delays)
    for i in [0..15]
      out.write(delays[i] + ' ')
    out.write(result + '\n')
    console.log it
    if result > result_max
      delays_max = delays
      result_max = result
  out.write('max: ')
  for i in [0..15]
      out.write(delays_max[i] + ' ')
  out.write(result_max + '\n')

# experiment()

experimentf = () ->
  out = fs.createWriteStream './experiments/rand/3.data'
  flips_max = []
  result_max = -1
  flips = [1,1,1,1]
  for it in [0..60]
    for i in [0..3]
      flips[i] = 3 * random()
    result = avgSpeed (flips)
    for i in [0..3]
      out.write(flips[i] + ' ')
    out.write(result + '\n')
    console.log it
    if result > result_max
      flips_max = flips
      result_max = result
  out.write('max: ')
  for i in [0..3]
    out.write(flips_max[i] + ' ')
  out.write(result_max + '\n')

#experimentf()

3