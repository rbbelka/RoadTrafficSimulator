import numpy as np
import json
import os
from scipy import optimize
from pprint import pprint

# EXAMPLE---------------------------------------------------------
def example():
  params = (2, 3, 7, 8, 9, 10, 44, -1, 2, 26, 1, -2, 0.5)
  def f1(z, *params):
    x, y = z
    a, b, c, d, e, f, g, h, i, j, k, l, scale = params
    return (a * x**2 + b * x * y + c * y**2 + d*x + e*y + f)

  def f2(z, *params):
    x, y = z
    a, b, c, d, e, f, g, h, i, j, k, l, scale = params
    return (-g*np.exp(-((x-h)**2 + (y-i)**2) / scale))

  def f3(z, *params):
    x, y = z
    a, b, c, d, e, f, g, h, i, j, k, l, scale = params
    return (-j*np.exp(-((x-k)**2 + (y-l)**2) / scale))

  def f(z, *params):
    x, y = z
    a, b, c, d, e, f, g, h, i, j, k, l, scale = params
    return f1(z, *params) + f2(z, *params) + f3(z, *params)

  x0 = np.array([2., 2.])     # Initial guess.

  np.random.seed(555)   # Seeded to allow replication.
  res = optimize.anneal(f, x0, args=params, schedule='boltzmann', 
			full_output=True, maxiter=500, lower=-10,
			upper=10, dwell=250, disp=True)

  print(res)
#-----------------------------------------------------------------

wi = ['intersection153', 'intersection154']

def run_experiment(delays, *params):
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
  x0 = [1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0]
  np.random.seed(555)   # Seeded to allow replication.
  res = optimize.anneal(run_experiment, x0, schedule='boltzmann', 
			full_output=True, maxiter=500, lower=[0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1],
			upper=[3.0,3.0,3.0,3.0,3.0,3.0,3.0,3.0], dwell=5, disp=True)
  print(res)


if __name__ == "__main__":
    main()