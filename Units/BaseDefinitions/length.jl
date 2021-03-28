
names = ["Meters", "Kilometers", "Millimeters"]
symbols = ["m", "km", "mm"]
factors = [1, 1/1000, 1000]

const distance = Dict(:distance => 1)

define_base_units(names, symbols, factors, distance, names[1])

