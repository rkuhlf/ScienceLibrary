


names = ["Seconds", "Kiloseconds", "Milliseconds"]
symbols = ["s", "ks", "ms"]
factors = [1, 1/1000, 1000]

const time = Dict(:time => 1)

define_base_units(names, symbols, factors, time, names[1])
