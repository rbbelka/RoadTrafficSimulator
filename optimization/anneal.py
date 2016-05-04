import numpy as np
import json
import os
from scipy import optimize
from pprint import pprint

wi = ['intersection153', 'intersection154']
T = 3.0
B = 0.1

def run_experiment(delays, *params):
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
  return res
  
  

def experiment():
  data = None
  with open('../experiments/map.copy.json', 'r') as data_file:    
    data = json.load(data_file)
    for intersection in data["intersections"]:
      #data["intersections"][intersection]["controlSignals"]["delayMultiplier"] = [1,1,1,1]
      print( data["intersections"][intersection]["controlSignals"]["delayMultiplier"] )
  
  with open('../experiments/map.copy.json', 'w') as data_file:
    json.dump(data, data_file)

def main():
  #experiment()
  #run_experiment([1,1,1,1,1,1,1,1])
  x0 = [1.0,1.0,3.0,3.0,1.0,1.0,3.0,3.0]
  np.random.seed(555)   # Seeded to allow replication.
  res = optimize.anneal(run_experiment, x0, schedule='boltzmann', full_output=True, maxiter=500, lower=B, upper=T, dwell=30, disp=True)
  print(res)


if __name__ == "__main__":
    main()