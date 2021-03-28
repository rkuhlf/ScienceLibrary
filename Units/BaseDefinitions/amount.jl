# Definitely finished this one, might have to use it a bit wierd when I add mass conversions for amount of things with moles

abstract type Amount <: Unit end


# All amount units measure in one dimensions
# If there is a different one (square dozens), it can be overrided
measures(::Amount) = Dict(:amount => 1)
measures(::Type{<:Amount}) = Dict(:amount => 1)


struct Singular <: Amount
  Singular(v=1) = Unit(nothing, v)
end

Singular(v::Value) = convert(Singular, deepcopy(v))


macro def_amount(name, symbol)
  @eval begin
    mutable struct $name <: Amount
      $name(v=1) = Unit($name, v) 
    end

    $name(temp::Value) = convert($name, deepcopy(temp))

    $symbol = $name()
  end
end

@def_amount(Dozens, doz)
@def_amount(Moles, mol)
@def_amount(Scores, score)
@def_amount(HalfDozens, hfdoz)
@def_amount(BakersDozens, bkdoz)
@def_amount(Reams, r)
@def_amount(LongHundreds, lg100)
@def_amount(Gross, gr)
@def_amount(GreatGross, grgr)
@def_amount(SmallGross, smgr)

const all_amounts = Union{Type{Singular}, Type{Dozens}, Type{Moles}, Type{Scores}, Type{HalfDozens}, Type{BakersDozens}, Type{Reams}, Type{LongHundreds}, Type{Gross}, Type{GreatGross}, Type{SmallGross}}

@def_conversions(Singular, Singular, all_amounts, 1)
@def_conversions(Dozens, Singular, all_amounts, 1/12)
@def_conversions(Moles, Singular, all_amounts, 1/avogadros_number)
@def_conversions(Scores, Singular, all_amounts, 1/20)
@def_conversions(HalfDozens, Singular, all_amounts, 1/6)
@def_conversions(BakersDozens, Singular, all_amounts, 1/13)
@def_conversions(Reams, Singular, all_amounts, 1/500)
@def_conversions(LongHundreds, Singular, all_amounts, 1/120)
@def_conversions(Gross, Singular, all_amounts, 1/(12^2))
@def_conversions(GreatGross, Singular, all_amounts, 1/(12^3))
@def_conversions(SmallGross, Singular, all_amounts, 1/120)


