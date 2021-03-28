import Base: +, -, *, /, ^, ==, convert, promote_rule

abstract type Unit end
abstract type DerivedUnit <: Unit end

include("value.jl")



include("baseUnits.jl")


include("derivedUnits.jl")

AnyUnit = Union{Type{<:Unit}, Unit}


include("BaseDefinitions/defineBase.jl")



# Promote rules are only necessary if I want to implement any automatic conversion. I probably should, that way addition works in the best manner possible


include("DerivedDefinitions/defineDerived.jl")

include("priorities.jl")

include("conversions.jl")


# End Goals
# ---------

# Molecules should have the functionality of units
# acid = 1 Molecule("H_2CO_3") # automatically given the 'formula units'
# println(acid) -> 1 formula units H_2CO_3
# grams(acid) # should return 0.00132 g H_2CO_3
# moles(acid) # -> 0.00000...001 mol H_2CO_3

# mass = 3g
# water = Molecule(Dict(H=>2, O=>1))
# mass = mass (water) # translates to mass * water

# The get moles function should be defined for the chemical type
# It has to access the molar mass from the units
# moles_of_material = moles(mass)

# force = 24 N
# pressure = force / area
# pressure = Pascals(pressure)