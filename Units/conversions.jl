# Put all the conversion code in the same file that way it is easier to figure out how to refactor


# find the measures of a unit dictionary
function measures(d::Dict{AnyUnit, Integer})
  total_measures = Dict{Symbol, Integer}()
  for (unit, frequency) in d
    total_measures += measures(unit) * frequency
  end

  total_measures
end

"""
Cancel out as many units as possible, not considering base units of derived units or possible simplifications of things
"""
function simplify_units(v::Value)

  println("")
  println("Simplifying")
  replaced_this_iteration = true

  while replaced_this_iteration == true
    unit_array = Array(v.units)
    replaced_this_iteration = false
    for i in 1:length(unit_array)-1
      for j in i+1:length(unit_array)
        println(unit_array)
        # If they have opposite signs and measure the same thing, convert according to promote rule
        if measures(unit_array[i].key) == measures(unit_array[j].key) && sign(unit_array[i].value) != sign(unit_array[j].value) && !(unit_array[j].key isa Thing || unit_array[i].key isa Thing)
          println(unit_array[i].key, unit_array[j].key)
          target = promote_rule(unit_array[i].key, unit_array[j].key)
          # Convert the value to the target type
          println("Converting value to ", target)
          v = convert(target, v; affect_things=false)
          replaced_this_iteration = true
          break
        end
      end
    end
  end

  return (v.value, v.units)
end


function convert_base!(key::Thing, v::Value)
  previous_measures = measures(key)
  for unit_set in default_units(key)
    if measures(unit_set[:units]) == previous_measures
      multiplier = unit_set[:multiplier]

      reset_measures(key)
      v.units -= unit_set[:units]

      v.value /= multiplier
      break
    end
  end
  println(v.units)
end

# Conversion from mKg/g measured by distance back to Kg throws an infinite loop. Probably because it can convert Carrots and grams.
# BASE UNITS
"""
Provide the maximum number of times you want the unit added in, as well as the minimum number of times
You can make it convert to base_units if you would like
"""
function convert(name::Type{<:Unit}, v::Value; max_iters=Inf,min_iters=1, convert_to_base_units=false, simplify=true, affect_things=true)
  replaced_so_far = 0
  println("Starting at ", v)
  
  if convert_to_base_units
    v = as_base_units(v)
  end

  # If we have replaced the minimum and it wouldn't simplify any more to continue replacing
  while !(replaced_so_far >= min_iters && !should_replace(v.units, name; affect_things=affect_things)) && replaced_so_far < max_iters
    replaced = false

    for (key, frequency) in v.units
      if key isa Thing && affect_things
        # We have to do something totally different
        if convertible(key, name)
          # There's definitely one that works, so we can go ahead and unconvert any of the previous configurations
          convert_base!(key, v)
          println("Reset measures ", v)

          for unit_set in default_units(key)
            if measures(unit_set[:units]) == measures(name)
              # Required because otherwise it will only modify the copy
              delete!(v.units, key)
              key.measures = measures(name)
              v.units[key] = frequency
              multiplier = unit_set[:multiplier]
              v.units += unit_set[:units]

              v.value *= multiplier

              replaced_so_far += 1
              replaced = true

              println("Replaced ", v)
              break
            end
          end
        end

      # This unit can be converted because it measures the same thing
      elseif measures(name) == measures(key) && key != name
        multiplier = convert(name, key)
        # replace the old units
        increment_item(v.units, key, -sign(frequency))
        increment_item(v.units, name, sign(frequency))

        v.value *= multiplier ^ sign(frequency) # multiply by exchange factor
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
    return convert(name, v; max_iters=max_iters, min_iters=min_iters, convert_to_base_units=true)
  end

  if simplify
    (v.value, v.units) = simplify_units(v)
  end

  Value(v.value, v.units)
end


"Figure out whether it is shorter if we continue replacing units"
# This isn't the fastest way to do it, but the library isn't really built for speed and extra safeguards are alright
function should_replace(units::Dict{AnyUnit, <:Number}, type_of_unit::Type{<:Unit}; affect_things=true)
  # We want to keep going if there are any that don't match the base unit
  for (unit, occurences) in units
    if unit isa Thing && !affect_things
      continue
    end
    
    if convertible(unit, type_of_unit)
      return true
    end
  end

  return false
end






function convertible(t::Thing, ::Type{Singular})
  measures(t) != Dict()
end


# AMOUNTS

# Terribly repetitive
# make converting to Singular do all of the usual unit conversion stuff, but don't add the new key
function convert(::Type{Singular}, t::Value; max_iters=Inf,min_iters=1, convert_to_base_units=false, affect_things=true)
  replaced_so_far = 0
  
  if convert_to_base_units
    t = as_base_units(t)
  end

  while (replaced_so_far < min_iters || should_replace(t.units, Singular)) && replaced_so_far < max_iters
    replaced = false
    for (key, frequency) in t.units
      # This unit can be converted because it measures the same thing
      if measures(Singular) == measures(key) && key != Singular
        multiplier = convert(Singular, key)
        # replace the old units
        increment_item(t.units, key, -1)

        t.value *= multiplier # multiply by exchange factor
        replaced_so_far += 1
        replaced = true
      elseif key isa Thing && affect_things && convertible(key, Singular)
        # Unconvert a thing back to measuring by number
        convert_base!(key, t)
      end
    end

    # If we go through the whole loop and nothing has been replaced, something's possible broken, but we definitely need to stop
    if !replaced
      break
    end

  end

  return Value(t.value, t.units)
end

function convert(name::Type{<:Amount}, t::Value; max_iters=Inf,min_iters=1, convert_to_base_units=false)
  replaced_so_far = 0
  
  if convert_to_base_units
    t = as_base_units(t)
  end

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


  if replaced_so_far == 0 && min_iters > 0
    if convert_to_base_units == false
      return convert(name, t; max_iters=max_iters, min_iters=min_iters, convert_to_base_units=true)
    else
      # Convert from singular, since there are no existing amounts to convert from 
      t.units[Singular] = 1
      return convert(name, t; max_iters=max_iters, min_iters=min_iters, convert_to_base_units=true)
    end
  end


  return Value(t.value, t.units)
end


# DERIVED UNITS
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
