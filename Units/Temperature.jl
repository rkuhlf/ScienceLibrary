# https://erik-engheim.medium.com/defining-custom-units-in-julia-and-python-513c34a4c971
# Throw a warning if you are multiplying anything other than Kelvin

import Base: +, -, *, convert, promote_rule


abstract type Temperature end


types = [:Celsius, :Kelvin, :Fahrenheit]

for T in types
  @eval begin
    struct $T <: Temperature
      value::Float64
    end

    # If they are the same units, then just add their values together
    +(x::$T, y::$T) = $T(x.value + y.value)
    -(x::$T, y::$T) = $T(x.value - y.value)
    # Multiplication by a non-units number
    *(x::Number, y::$T) = $T(x*y.value)
  end
end

promote_rule(::Type{Kelvin}, ::Type{Celsius}) = Kelvin
promote_rule(::Type{Fahrenheit}, ::Type{Celsius}) = Celsius
promote_rule(::Type{Fahrenheit}, ::Type{Kelvin}) = Kelvin

convert(::Type{Kelvin}, t::Celsius) = Kelvin(t.value + 273.15)
convert(::Type{Celsius}, t::Kelvin) = Celsius(t.value - 273.15)
convert(::Type{Kelvin}, t::Fahrenheit) = Kelvin(Celsius(t))
convert(::Type{Celsius}, t::Fahrenheit) = Celsius((t.value - 32) * 5/9)
convert(::Type{Fahrenheit}, t::Celsius) = Fahrenheit(t.value * 9/5 + 32)
convert(::Type{Fahrenheit}, t::Kelvin) = Fahrenheit(Celsius(t))

for T in types, S in types
  if S != T
    @eval $T(temp::$S) = convert($T, temp)
  end
end

# The ellipses destructures the command, so it ends up x, y after they have been promoted
+(x::Temperature, y::Temperature) = +(promote(x,y)...)
-(x::Temperature, y::Temperature) = -(promote(x,y)...)


function show(io::IO, k::Kelvin)
  print(io, "$(k.value) K")
end

function show(io::IO, c::Celsius)
  print(io, "$(c.value)°C")
end

function show(io::IO, f::Fahrenheit)
  print(io, "$(f.value)°F")
end

const °C = Celsius(1)
const °F = Fahrenheit(1)
const K = Kelvin(1)
