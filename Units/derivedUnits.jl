
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





