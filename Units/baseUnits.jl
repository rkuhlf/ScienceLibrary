
function Unit(self_unit, v = 1)
  if isnothing(self_unit)
    return Value(v)
  end
  Value(v, Dict(self_unit=>1))
end

@mustimplement measures(u::Unit)

convertible(unit::Type{<:Unit}, target_unit) = measures(unit) == measures(target_unit) && unit != target_unit

# This hash function determines how the units dictionary works
# Hash documentation says something about it being good to also define isequal and widen, reread it
function Base.hash(u::Type{<:Unit})
  hash([measures(u), Symbol(u)])
end

# Basically only for Things
function Base.hash(u::Unit)
  hash([measures(u), Symbol(u)])
end

function ==(a::Unit, b::Unit)
  measures(a) == measures(b) &&
  typeof(a) == typeof(b)
end



macro def_unit(name, measures, symbol)
  @eval begin
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



# TODO: fix error :
# When you create seconds / kiloseconds, then attempt to convert to seconds, it runs into an infinite loop