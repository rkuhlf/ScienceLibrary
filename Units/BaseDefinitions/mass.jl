
names = ["Grams", "Kilograms", "Milligrams"]
symbols = ["g", "kg", "mg"]
factors = [1, 1/1000, 1000]

const mass = Dict(:mass => 1)

define_base_units(names, symbols, factors, mass, names[1])
