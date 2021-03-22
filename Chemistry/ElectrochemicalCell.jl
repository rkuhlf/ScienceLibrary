struct ElectrochemicalCell {
  anode::Atom
  anode_solution::Fluid
  cathode::Atom
  cathode_solution::Fluid
}

function electricPotential(cell::ElectrochemicalCell; temperature=Celsius(25))
  standard_potential = cell.cathode.reduction_potential - cell.anode.reduction_potential
  # - RT/NF ln(Q)
  Q = molarity(cell.anode_solution) / molarity(cell.cathode_solution)
  anode_electrons = cell.anode_solution[cell.anode].charge
  cathode_electrons = cell.cathode_solution[cell.cathode].charge
  n = lcm(anode_electrons, cathode_electrons)

  # log translates to ln in julia
  adjustment = (8.31 * Kelvin(temperature)) / (n * 96485) * log(Q)

  # absolute value because if there is any value then there will be a voltage flow
  abs(standard_potential - adjustment)
end