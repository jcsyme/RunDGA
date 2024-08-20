# Run DiscreteGraphAlgorithms (RunDGA)


##  Algorithms

The DGA suite currently includes 5 different algorithms available for use. 


### Ant Colony Optimization (`aco`)

Ant colony optimzation includes the following parameters:

* **`beta`**:
	- **Description**: Exponentiation of heuristic value in probability term for each ant. Conceptually, it weights the heuristic in each ant's decision to include a vertex in the solution space.
	- **Default value**: 0.25
* **`heuristic`**:
	- *Description : The heuristic to use for guiding probabilities in ants. This heuristic should be set in conjunction with the objective function being optimized. By default, `betweenness_centrality` is used since the default objective function is `fragmentation`. However, the following options are available:
		- `betweenness_centrality`
		- `degree_centrality`
		- `eigenvector_centrality`
		- `katz_centrality`
	- **Default value**: `betweenness_centrality`
* **`init_colony_with_op_s`**:
	- **Description**: Boolean value indicating whether or not to initialize the ant colony to include an ant that includes the starting S specified. Only evaluated if a starting set $S$ is specified.
	- **Default value**: false
* **`num_elite`**:
	- **Description**: Specification of number of high performers to pass from generation to generation. See the section above on *Specifying Population Sizes* for more information on entering the value of this paramter. 
	- **Default value**: 0.5
* **`population_size`**: 
	- **Description**: `population_size` is used to specify the size of the ant colony. See the section above on *Specifying Population Sizes* for more information on entering the value of this paramter. 
	- **Default value**: 0.1
* **`rho`**:
	- **Description**: Evaporation rate of pheremones left behind by each ant; $0 \leq \rho \leq 1$
	- **Default value**: 0.1
* **`tau_0`**:
	- **Description**: Initial pheremone value $\tau_0$. Should be set with a consideration for the order of the objective function. For fragmentation, 1.0 has performed reasonably well in test cases.
	- **Default value**: 1.0

---


### Genetic (`genetic`)

The genetic optimzation algorithm includes the following parameters:

* **`init_colony_with_op_s`**:
	- **Description**: Boolean value indicating whether or not to initialize the ant colony to include an ant that includes the starting S specified. Only evaluated if a starting set $S$ is specified.
	- **Default value**: false
* **`num_elite`**:
	- **Description**: Specification of number of high performers to pass from generation to generation. See the section above on *Specifying Population Sizes* for more information on entering the value of this paramter. 
	- **Default value**: 0.05
* **`population_size`**: 
	- **Description**: `population_size` is used to specify the size of the ant colony. See the section above on [Specifying Population Sizes](#specifying-population-sizes) for more information on entering the value of this paramter	- **Default value**: 0.1

---


### Gradient Descent (`graddesc`)

Gradient descent does not include any parameters, but global options can be set for this algorithm, including `max_iter` and `max_iter_no_improvement`. See [Global Parameters](#global-parameters) for more information on these.

---


### Greedy Stochastic (`gs`)

* **`epsilon`**: 
	- **Description**: threshold used to denote convergence. If the directional value of the change in the objective function is less than epsilon, then the algorithm will terminate.
  	- **Default value**: 0.000001
* **`randomize_swap_count`**
	- **Description**: Randomize the number of vertices that are swapped at each iteration? If `false` (default), then only one vertex is swapped at each step.
  	- **Default value**: false
  
---


### Simulated Annealing (`sann`)

* **`alpha`**: 
	- **Description**: Scalar applied in temperature function (see `?sann_temperature` for more information)
	- **Default value**: 1.0
* **`max_exploration_error`**: 
	- **Description**: Error acceptance threshold in late cooling phase; if an error relative to the known best exceeds this value, then SANN will reset to the best known parameters and restart.
	- **Default value**: 0.25
* **`q`**: 
	- **Description**: Exponential cooling rate in temperature function (see `?sann_temperature` for more information)
	- **Default value**: 0.5
* **`randomize_swap_count`**
	- **Description**: Randomize the number of vertices that are swapped at each iteration? If `false` (default), then only one vertex is swapped at each step.
  	- **Default value**: false
* **`restart_from_best_fraction`**
	- **Description**: Fraction of time where the algorithm checks the error and reverts to the best known outcome if attempt errors are too high (i.e., if they exceeed `max_exploration_error`). This process is only applied in the latter part of the algorithm--e.g., starting at time `params_optimization.max_iter*(1 - restart_from_best_fraction)` to reduce the chances of getting caught in a dominated local extrema.
	- **Default value**: 0.33
	
---


### Specifying Population Sizes

Ant colony optimization (`aco`) and Genetic optimization (`genetic`) both rely on populations to test and select candidate solutions. These algorithms additionally include *elitism*, or the assurance that the best solution at each iteration will be passed on to the next iteration. This condition ensures that iterative trajectories will be weakly monotonic. 

In general, there are two key population parameters to think about in these population-based algorithms:

1. **`population_size`**: the number of organisms in each population to specify. The population size can be set in one of two ways:
    *  **Fraction** If entered as a float $0 < p < 1$, then `DiscreteGraphAlgorithms` assumes that $p$ represents the expected total proportion of the vertices that are covered. For example, with $|V| = 1000$ vertices and a target removal of $|S| = 4$ vertices, a value of $p = 0.05 \implies$ that the expected coverage should be $|V|p = 50$ vertices $\implies$ a population of $\left\lceil\frac{|V|p}{|S|}\right\rceil = 13$.
    *  **Integer** If entered as an integer $p \in \mathbb{N}, p > 0$, then`DiscreteGraphAlgorithms` assumes that this is the population size of organisms to spawn.
    
1. **`num_elite`**: or the number of elite organisms to pass to the next iteration. If the number of elites is greater than 1, than top performers are passed to the next generation. The number of elites can be passed in one of two ways: 
	* **Fraction** If entered as a float $0 < p < 1$, then `DiscreteGraphAlgorithms` assumes that it represents represents the top fraction of the population. For example, with a population of 50 and a value of 0.05, then the top $\lceil50\times0.05\rceil = 3$ performers will be passed to the next generation.
    * **Integer** If entered as an integer $p \in \mathbb{N}, p > 0$, then`DiscreteGraphAlgorithms` assumes that this is the number of elites to pass. This is always capped at 50% of the population.


### Other Parameters

Each algorithm can accept certain global parameters that are in place to facilitate tractable execution. Furthermore, default values for global parameters can be set, which are then used for algorithms if an algorithm-specific value is not passed. 

These parameters are delineated below. 

* **`max_iter`**:
	- **Description**: Maximum number of iterations to allow. Shold be set depending on characteristics of graph (size, density, etc.); in larger graphs, this number might be smaller to reduce the likelihood of a long runtime, while in smaller/less-dense graphs, the user might tolerate more iterations.
	- **Default value**: 1000
* **`max_iter_no_improvement `**:
	- **Description**: The maximum number of iterations to continue the algorithm if there is no improvement in the objective function. Use this parameter with care
	- **Default value**: 100

---




##  Objective Functions

Currently, the `DiscreteGraphAlgorithms` package only supports the use of maximizing fragmentation *CITE:BORGATTI* . However, it is actively being expanded to support the use additional objective functions and directionality.



##  The Command Line Utility


## Specifying Parameters 

Parameters that govern algorithmic behavior can significantly affect the performance of algorithms. For example, the size of an ant colony or genetic organism affects the breadth of the space that is explored but slows iteration time. 

These parameters can be specified in one of two ways:

1. At the command line
1. In a configuration file

In the event of a conflict between the two, the command line takes precedence. This allows for users to set expected defaults for a problem in the configuration file, then experiment with tweaking different parameteriations more easily at the command line.


###  At the Command Line

Parameters are entered at the command line using flags. For example, 

```julia run_dga.jl --aco-rho 0.4```


###  The Configuration File

Running multiple algorithms at the same time could introduce long, confusing chains of command line arguments. To support easier specification of algorithm parameters, `RunDGA` lets you specify parameters in a configuration file. This file, `config.yaml` includes parameters for both global and algorithm-specific use.


