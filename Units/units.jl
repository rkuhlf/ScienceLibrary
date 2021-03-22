import Base: +, -, *, /, convert, promote_rule

abstract type Unit end
abstract type DerivedUnit <: Unit end


mutable struct Value
  value::Float64
  units::Dict{Type{<:Unit}, Int8}

  Value(v=1, u=Dict()) = new(v, u)
end

function measures(v::Value)
  measures = Dict()
  for (key, value) in units

    # The exponent will multiply the number of times it appears in the dictionary
    measures = merge(+, measures, measures(key) * value)
  end

  measures
end

function +(x::Value, y::Value)
  # check that the measures of each component matches up
  # Otherwise, throw an error
  array_matches(measures(x), measures(y)) || error("You cannot add values with different units.")

  # TODO: convert all of the units that have matching measures
  # Try to get it working so that promote rules work here

  return x.value + y.value
end


function *(x::Value, y::Value)
  # the units get added together
  units = merge(+, x.units, y.units)
  
  Value(x.value * y.value, units)
end

function /(x::Value, y::Value)
  # the units get added together
  units = x.units - y.units
  
  Value(x.value / y.value, units)
end

*(x::Number, y::Value) = Value(x * y.value, y.units)
# I don't know why this second one is necessary, but it asked for it at one poitn
*(y::Value, x::Int64) = Value(x * y.value, y.units)

# I don't think it needs to store the base units
# The only possible negative impact is that it may be harder to figure out the promote_rule/conversion code
function Unit(self_unit, v = 1)
  # Might be okay to just throw it into the meters class, then define everything with a macro
  Value(v, Dict(self_unit=>1))
end

@mustimplement measures(u::Unit)

# Only need to hash the parts that determine what everything else is. This isn't enough to hash it, currently
# TODO: incorporate some representation of the conversion factors, or just the name (I think I did it, not sure)
Base.hash(u::Type{Unit}) = hash(measures(u), typeof(u))


# I think the hash is extended from the Unit struct
function DerivedUnit(self_unit, v=1)
  Unit(self_unit, v)
end
# When converting to a derived unit, you need to know what it is made of
@mustimplement base_units(u::DerivedUnit)
# This is how much you multiply by when you convert the value to its base units
@mustimplement multiplier(u::DerivedUnit)

function measures(u::Type{<:DerivedUnit})
  total_measures = Dict{Any, Int8}()
  units = base_units(u)

  for (unit, frequency) in units
    total_measures += measures(unit) * frequency
  end

  return total_measures
end


function as_base_units(v::Value)
  v = deepcopy(v)
  for (unit, frequency) in v.units
    if unit <:DerivedUnit
      v.value /= multiplier(unit)
      increment_item(v.units, unit, -frequency)
      v.units += base_units(unit) * frequency
    end
  end

  v
end



"Figure out whether it is shorter if we continue replacing units"
# This isn't the fastest way to do it, but the library isn't really built for speed and extra safeguards are alright
function should_replace(units::Dict{Type{<:Unit}, <:Number}, type_of_unit::Type{<:Unit})
  # We want to keep going if there are any that don't match the base unit
  for (unit, occurences) in units
    if measures(unit) == measures(type_of_unit) && unit != type_of_unit
      return true
    end
  end

  return false
end

macro def_unit(name, measures, symbol)
  #println(name)
  @eval begin
    #println(name)
    #println($name)
    #println($(Symbol(name)))
    mutable struct $name <: Unit
      $name(v=1) = Unit($name, v) 
    end

    # Probably okay to have the both of these
    measures(u::$name) = $measures
    measures(u::Type{$name}) = $measures    

    # Need to make a copy, Otherwise it modifies it in place
    # That would be strange behavior for numbers
    $name(temp::Value) = convert($name, deepcopy(temp))

    $symbol = $name()
  end
end

"""
Provide the maximum number of times you want the unit added in, as well as the minimum number of times
You can make it convert to base_units if you would like
"""
function convert(name::Type{<:Unit}, t::Value; max_iters=Inf,min_iters=1, convert_to_base_units=false)
  replaced_so_far = 0
  
  if convert_to_base_units
    t = as_base_units(t)
  end

  # If we have replaced the minimum and it wouldn't simplify any more to continue replacing
  while !(replaced_so_far >= min_iters && !should_replace(t.units, name)) && replaced_so_far < max_iters
    replaced = false
    for (key, frequency) in t.units
      # This unit can be converted because it measures the same thing
      if measures(name) == measures(key) && key != name
        multiplier = convert(name, key)
        # replace the old units
        increment_item(t.units, key, -1)
        increment_item(t.units, name, 1)

        t.value *= multiplier # multiply by exchange factor
        replaced_so_far += 1
        replaced = true
      end
    end

    # If we go through the whole loop and nothing has been replaced, something's possible broken, but we definitely need to stop
    if !replaced
      break
    end
  end

  # If we didn't replace any and they really wanted us to, we should probably try harder
  if replaced_so_far == 0 && min_iters > 0 && convert_to_base_units == false
    return convert(name, t; max_iters=max_iters, min_iters=min_iters, convert_to_base_units=true)
  end

  Value(t.value, t.units)
end

macro def_derived(name, base, symbol, multiplier=1)
  @eval begin
    struct $name <: DerivedUnit
      $name(v=1) = DerivedUnit($name, v) 
    end

    base_units(::Type{$name}) = $base
    multiplier(::Type{$name}) = $multiplier

    $name(temp::Value) = convert($name, deepcopy(temp))

    $symbol = $name()
  end
end

function should_replace(units::Dict{Type{<:Unit}, <:Number}, type_of_unit::Type{<:DerivedUnit})
  # It's trickier for derived units
  # We want to keep going if it would reduce the total number of units, but not if it would stay the same 
  initial = total_values(units)

  total_units_to_remove = base_units(type_of_unit)

  # Subtract all the base units that the replacement would take away, and add the replacement back in
  # This doesn't include any derived units found within the value that could be simplified
  # This part actually matters - ex. Jm -> N is not a favorable thing
  # Actually, it should work if we convert everything to base units at the very beginning
  new_units = total_values(units - total_units_to_remove) + 1

  return new_units < initial
end


function convert(name::Type{<:DerivedUnit}, t::Value; max_iters=Inf,min_iters=1, convert_to_base_units=true)
  replaced_so_far = 0
  
  if convert_to_base_units
    t = as_base_units(t)
  end


  # Make sure all of the base units match the base units of the thing we want to convert to
  for (unit, _) in base_units(name)
    t = unit(t)
  end

  # If we have replaced the minimum and it wouldn't simplify any more to continue replacing
  while (should_replace(t.units, name) || replaced_so_far < min_iters) && replaced_so_far < max_iters

    # Because we 'should' replace, we know it is possible
    t.units -= base_units(name)
    increment_item(t.units, name)
    t.value *= multiplier(name)

    replaced_so_far += 1
  end

  Value(t.value, t.units)
end



# The base value has to be the same for all values that you want to be convertible
macro def_conversions(name, base, union, multiplier)
  @eval begin
    # This is still not working, it is only compiling
    convert(::Type{$name}, t::$union) = convert($base, t) * $multiplier
    convert(::Type{$base}, ::Type{$name}) = 1 / $multiplier
  end
end


# Loop through variable names
# DISTANCE
# TODO: Turn this into a macro that will be used for every single base unit
names = ["Meters", "Kilometers", "Millimeters"]
symbols = ["m", "km", "mm"]
factors = [1, 1/1000, 1000]

const distance = "Dict(:distance => 1)"

# This seems like a terrible way to do it
for i in 1:length(names)
  prog = eval("@def_unit(" * names[i] * "," * distance * "," * symbols[i] * ")")

  eval(Meta.parse(prog))
end

type_names = map(name -> "Type{" * name * "}", names)
prog = "Union{" * join(type_names, ", ") * "}"

Distance = eval(Meta.parse(prog))

base_unit = "Meters"

for i in 1:length(names)
   # Distance can just be passed since it is a global variable
  prog = eval("@def_conversions(" * names[i] * ", " * base_unit * ", Distance, " * repr(factors[i]) * ")")

  eval(Meta.parse(prog))
end 




# TIME

const time = Dict(:time => 1)
@def_unit(Seconds, time, s)

# Define unions for different versions of base units
Time = Union{Seconds}



@def_conversions(Seconds, Seconds, Time, 1)


# DERIVED
# These definitely need no complex eval for concision
@def_derived(Mach, Dict(Meters => 1, Seconds => -1), Ma, 1/343)

# Don't have to have any conversions for derived numbers




# Promote rules are only necessary if I want to implement any automatic conversion. I probably should, that way addition works in the best manner possible

# include("Temperature.jl")





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