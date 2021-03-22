mutable struct Fluid {
  volume:Float64
  in_solution:Dict{Chemical, Float64}
}


molarity(solution::Fluid, chemical::Chemical) = solution.in_solution[chemical] / solution.volume