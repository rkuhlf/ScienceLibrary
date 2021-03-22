
# I don't know if including this is the best class structure
# include("Element.jl")

# Contains a dictionary of elements or molecules, with each thing going to it's coefficient

# chemical = Union{Element, Molecule}

struct Molecule
  #elements::Union{Element, Molecule}
  elements::Dict{Union{Atom, Molecule}, Int8}
end

Chemical = Union{Atom, Molecule}