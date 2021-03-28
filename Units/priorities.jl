


function promote_rule(a::AnyUnit, b::AnyUnit)
  if typeof(a) != DataType
    a = typeof(a)
  end
  if typeof(b) != DataType
    b = typeof(b)
  end

  for unit in priorities
    if unit == a 
      return a
    end
    if unit == b
      return b
    end
  end
end

# I'm pretty sure I won't ever need to include any Thing in here
# Singular also isn't in this list, because it never conflicts. We already handle it as a special case
# TODO: actually handle it be fixing the way amounts are considered in measures (needs to be different)
# Put the one you want a conflict to be converted to closer to the top
priorities = [
  # Derived units
  Newtons,
  Mach,

  # Base units
  # Amounts
  Moles,
  Dozens,
  Scores,
  HalfDozens,
  BakersDozens,
  Reams,
  LongHundreds,
  Gross,
  GreatGross,
  SmallGross,

  # Mass
  Grams,
  Milligrams,
  Kilograms,

  # Length
  Meters,
  Millimeters,
  Kilometers,

  # Time
  Seconds,
]