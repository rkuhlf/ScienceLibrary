
mutable struct Value
  value::Float64
  units::Dict{Union{Type{<:Unit}, <:Unit}, Int8}

  Value(v=1, u=Dict()) = new(v, u)
end

# This is currently only for Things, but it's nice to have a general option
function Base.hash(u::Value)
  # Hashing the units is not working
  # I'll just go through everything and add it to an array
  to_hash = [u.value]

  for (unit, frequency) in u.units
    append!(to_hash, hash(unit))
    append!(to_hash, frequency)
  end

  hash(to_hash)
end

function ==(a::Value, b::Value)
  a.value == b.value &&
  a.units == b.units
end

function measures(v::Value)
  total_measures = Dict()
  for (key, value) in v.units
    if key isa Thing
      continue
    end

    # The exponent will multiply the number of times it appears in the dictionary
    total_measures = merge(+, total_measures, measures(key) * value)
  end

  total_measures
end

# This should really be a union of every single type that has a measures function
"""
Check if the two things have the same measures
By default, it won't consider amounts, since they don't really work like that
"""
# Is it better practice to have defaults be true, "exclude amounts"?
function measures_same(a, b; include_amounts=false)
  a_measures = measures(a)
  b_measures = measures(b)

  if !include_amounts
    delete!(a_measures, :amount)
    delete!(b_measures, :amount)
  end

  return a_measures == b_measures
end

function +(x::Value, y::Value)
  # This isn't great, but looping through all possible things on both sides also sucks
  x = Singular(x)
  y = Singular(y)
  # check that the measures of each component matches up
  # Otherwise, throw an error
  # This doesn't really work forThings that are in different forms
  measures(x) == measures(y) || error("You cannot add values with different units.")

  # Check that any things being added are perfectly matched
  x_counts = Dict{Type{<:Thing}, Number}()
  for (unit, frequency) in x.units
    if unit isa Thing
      x_counts[typeof(unit)] = frequency
    end
  end

  y_counts = Dict{Type{<:Thing}, Number}()
  for (unit, frequency) in y.units
    if unit isa Thing
      y_counts[typeof(unit)] = frequency
    end
  end

  x_counts == y_counts || error("You cannot add values of different things.")

  # TODO: convert all of the units that have matching measures
  # Try to get it working so that promote rules work here
  # Return the simplified version

  # Loop down through priorities, checking if anything already has units


  for unit in priorities
    if unit in keys(x.units) || unit in keys(y.units)
      convert(unit, x)
      convert(unit, y)

      if x.units == y.units
        break
      end
    end
  end


  return Value(x.value + y.value, x.units)
end

function -(x::Value, y::Value)
  x + -1 * y
end


function *(x::Value, y::Value)
  # the units get added together
  units = x.units + y.units
  
  Value(x.value * y.value, units)
end

function /(x::Value, y::Value)
  # the units get added together
  units = x.units - y.units
  
  Value(x.value / y.value, units)
end

function ^(x::Value, y::Integer)
  to_return = 1
  for i in 1:y
    to_return *= x
  end

  to_return
end

*(x::Number, y::Value) = Value(x * y.value, y.units)
# I don't know why this second one is necessary, but it asked for it at one poitn
*(y::Value, x::Int64) = Value(x * y.value, y.units)



function as_base_units(v::Value)
  v = deepcopy(v)
  for (unit, frequency) in v.units
    if unit isa DataType
      if unit <: DerivedUnit
        v.value /= multiplier(unit)
        increment_item(v.units, unit, -frequency)
        v.units += base_units(unit) * frequency
      end
    else
      # We actually have the instance of the unit
      # Don't need to do anything for Things because their units are actually represented elsewhere
    end
  end

  v
end