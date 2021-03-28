# Is this even that much different from the regular unit
# It is a little bit. DIFFERENCES:
# When you convert an amount of things to mass, you should still keep the things unit
# EX: kilograms(300 Airplanes) = 400000Kilograms of Airplanes
# Needs to be able to communicate information to the other units - it has to be all of the types
# Maybe have it be a measure of mass for molecules, but have a special marking that prevents it from deleting the thing in the units dictionary

# This stores things
# If you want to have 300 Airplanes
# If you want to have 30 mol H2O
# This is the airplanes, H2O, and 

# Pretty much, it just needs to be a way for the unit struct to store a reference to an object




# It's also slightly different because it needs to be stored as an instance of an object
# This may require some changes in other code
# In the dictionary it will be stored as H2O(blah...info)=>1
# Everything else will be a type, which almost makes sense
# I think it will probably necesitate some checks for ::Thing specifically

# the measures property is going to be a little different
# set equal to one of the measuring of one of the indices of the default_units method
# that way we can tell if it can be converted to mass again

# Sort of similar to derived units, since it needs to store what units it could be 
abstract type Thing <: Unit end

# Even if it's nothing, that needs to be explicit
@mustimplement default_units(::Thing)

# This is really more of a measured by. It is probably bad practice to have it share the variable name 
function measures(t::Thing)
  t.measures
end

function reset_measures(t::Thing)
  t.measures = Dict{Symbol, Integer}()
end


# TODO: Make this work for Things that are derived units. I think the should_convert code isn't going to work
"""
Can you convert this thing to the target unit (Bool)
"""
function convertible(t::Thing, target_unit)
  # Check if the measures is already what we are measuring. It will be converted in the other unit if the measures already match
  if (measures(t)) != measures(target_unit)
    # if it could be converted to this
    for unit_set in default_units(t)
      if measures(unit_set[:units]) == measures(target_unit)
        return true
      end
    end
  end

  return false
end

#=
function convert(::Type{Singular}, v::value)
  for (unit, frequency) in v.units
    if unit isa Thing
      if measures(unit) != Dict()
    end

  end
end=#




mutable struct Carrots <: Thing
  measures::Dict{Symbol, Integer}
  # This hopefully doesn't throw an infinite loop
  Carrots(v=1) = Unit(new(Dict()), v)
end


# Every single one will also have 'singular' as their units automatically
# This doesn't work because it thinks each index of the array only has Type => num pairs, not symbols, it needs to be a dictionary of a dictionary and a symbol=>Number
length_conversion = Dict(:units => Dict{AnyUnit, Integer}(Meters => 1), :multiplier => 0.178)
mass_conversion = Dict(:units => Dict{AnyUnit, Integer}(Grams => 1), :multiplier => 70)
default_units(::Carrots) = [length_conversion, mass_conversion]


# TODO: get conversions working for changing a value with Things in the units to one of the default_units it supports

# This is where my very WET code is going to mess me up. I will have to repeat changes across convert functions


# You can't convert a Value to a Thing like you could a Length


# This is wrong. Something about this being able to convert to any units. It needs to be fixed when you do the conversion. It should call the conversion to the default units. Actually it might work. Also I don't think convert is allowed to have anything other than a type as the first argument
""" 
Get the multiplier for the default unit set
"""
function convert(target_units::Dict{Type{<:Unit}}, c::Carrots)
  for unit_set in default_units(c)
    if target_units == unit_set.units
      return unit_set.multiplier
    end
  end 
end