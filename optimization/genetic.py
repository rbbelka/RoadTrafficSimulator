import numpy as np
import json
import os
from scipy import optimize
from pprint import pprint
from pyevolve import *
import pyevolve

wi = ['intersection153', 'intersection154']
T = 3.0
B = 0.1

def run_experiment(delays):
  # dirty hack
  for d in delays:
    if d < B or d > T:
      return 100000
  #
  data = None
  i = 0
  print(delays)
  # load data and create new configuration
  with open('../experiments/map.copy.json', 'r') as data_file:    
    data = json.load(data_file)
    for intersection in wi:
      for j in range(4):
	data["intersections"][intersection]["controlSignals"]["delayMultiplier"][j] = delays[i]
	i += 1
  # save new configuration
  with open('../experiments/map.copy.json', 'w') as data_file:
    json.dump(data, data_file)
  # run experiment
  os.system('coffee ../coffee/runner.coffee')
  # load experiment's result
  res = 0
  with open('../experiments/0.data', 'r') as data_file:  
    res = [float(x) for x in next(data_file).split()][0]
  return 1000.0-res
  

def GA():
  # Genome instance
  genome = G1DList.G1DList(8)

  # The evaluator function (objective function)
  genome.evaluator.set(run_experiment)
  genome.setParams(rangemin=B, rangemax=T)
  genome.mutator.set(Mutators.G1DListMutatorRealGaussian)
  genome.crossover.set(Crossovers.G1DListCrossoverSinglePoint)
  genome.initializator.set(Initializators.G1DListInitializatorReal)
  
  ga = GSimpleGA.GSimpleGA(genome)
  ga.selector.set(Selectors.GRouletteWheel)
  
  ga.setPopulationSize(10)
  ga.setGenerations(50)
  # Do the evolution, with stats dump
  # frequency of 10 generations
  
  ga.evolve(freq_stats=5)

  # Best individual
  print ga.bestIndividual()

def main():
  np.random.seed(555)   # Seeded to allow replication.
  GA()

if __name__ == "__main__":
    main()