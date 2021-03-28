# For some reason this doesn't accept any types. It says that it expectes UnionAll
function define_base_units(names, symbols, factors, measures_list, base_unit)
#function define_base_units(names::Array{String}, symbols::Array{String}, factors::Array{<:Number}, measures_list::Dict{Symbol, <:Number}, base_unit::String)
  # This seems like a terrible way to do it
  
  for i in 1:length(names)
    prog = eval("@def_unit(" * names[i] * "," * repr(measures_list) * "," * symbols[i] * ")")

    eval(Meta.parse(prog))
  end

  type_names = map(name -> "Type{" * name * "}", names)
  union_of_measures = "Union{" * join(type_names, ", ") * "}"
  

  
  for i in 1:length(names)
    # Distance can just be passed since it is a global variable
    prog = eval("@def_conversions(" * names[i] * ", " * base_unit * ", " * union_of_measures * ", " * repr(factors[i]) * ")")

    eval(Meta.parse(prog))
  end 
end



# The base value has to be the same for all values that you want to be convertible
macro def_conversions(name, base, union, multiplier)
  @eval begin
    # This is still not working, it is only compiling
    convert(::Type{$name}, t::$union) = convert($base, t) * $multiplier
    convert(::Type{$base}, ::Type{$name}) = 1 / $multiplier
  end
end



include("length.jl")
include("time.jl")
include("brightness.jl")
include("charge.jl")
include("temperature.jl")
include("mass.jl")
# This amount one will also store out what you are holding
include("amount.jl")
include("thing.jl")
