import Base: *, -, +

function Array(d::Dict)
  arr = []

  for (k, v) in d
    arr = [arr; (key=k, value=v)]
  end

  arr
end

function *(d::Dict{<:Any, <:Number}, n::Number)
  d = deepcopy(d)
  for (key, value) in d
    d[key] = value * n
  end

  d
end

function -(a::Dict{<:Any, <:Number}, b::Dict{<:Any, <:Number})
  a = deepcopy(a)
  for (key, value) in b
    increment_item(a, key, -value)
  end

  a
end

function +(a::Dict{<:Any, <:Number}, b::Dict{<:Any, <:Number})
  a = deepcopy(a)
  for (key, value) in b
    increment_item(a, key, value)
  end

  a
end

# I have no idea if this is a thing you shouldn't do, but here it is
+() = 0
total_values(d::Dict{<:Any, <:Number}) = +(abs.(values(d))...)

# TODO: add tests for this since I'm not 100% sure it works
function array_matches(a, b)
  if length(a) != length(b)
    return false
  end

  u = unique(a)

  a_count = Dict([(i,count(x->x==i,a)) for i in u])
  b_count = Dict([(i,count(x->x==i,b)) for i in u])

  for (key, value) in a_count
    # println(key, value)
    if value != b_count[key]
      return false
    end
  end

  true
end

function decrement_item(dictionary, key)
  increment_item(dictionary, key, -1)
end

function increment_item(dictionary, key, direction=1)
  if haskey(dictionary, key)
    dictionary[key] += direction
    if dictionary[key] == 0
      delete!(dictionary, key)
    end
  else
    dictionary[key] = direction
  end
end

# From the graphics library
macro mustimplement(sig)
  fname = sig.args[1]
  arg1 = sig.args[2]
  if isa(arg1,Expr)
    arg1 = arg1.args[1]
  end
  :($(esc(sig)) = error(typeof($(esc(arg1))),
                        " must implement ", $(Expr(:quote,fname))))
end

