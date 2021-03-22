# Want to have all of the elements, so that they can be initialized with H() or Hydrogen()
# This will be an abstract Element 'class'
# What functions does it need - probably nothing, it just has to store data

# Store everything in moles
# Functions that need something in grams will be calculated on the spot


# This should definitely be a unit. It can have a base element thing too if that is necessary
mutable struct Atom
  molar_mass::Float64
  moles
  # in an electrochemical cell, the voltage that this metal can generate
  reduction_potential::Float64
  oxidation_state::Int8

  # Convert whatever is passed in to moles
  # Element(molar_mass; moles, mass)
  Element(molar_mass, reduction_potential; moles=1, oxidation_state=0) = new(molar_mass, reduction_potential, moles, oxidation_state)
end

# This needs to be more based in the moles as a unit class
mass(e::Atom) = e.moles * e.molar_mass