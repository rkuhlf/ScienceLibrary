include("Helpers.jl")
include("Units.units.jl")

include("Chemistry/Element.jl")
include("Chemistry/Elements.jl")
include("Chemistry/Molecule.jl")
include("Chemistry/Fluid.jl")
include("Chemistry/ElectrochemicalCell.jl")



# water = Molecule(Dict(Hydrogen => 2, Oxygen => 1))

# println(water)

# CONCENTRATION CELL

aluminum_ion = deep_copy(Aluminum)
aluminum_ion.oxidation_state = 3
# I want this to say 1L, 3 Al3+, and have it work fine
solution1 = Fluid(1, aluminum_ion)

aluminum_ion.oxidation_state = 3
# creates a 0.5 Molar solution
solution2 = Fluid(2, aluminum_ion)

cell = ElectrochemicalCell(Aluminum, solution1, Aluminum, solution2)

println(electricPotential(cell))
