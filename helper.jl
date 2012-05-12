# count number of unique elements in array
function num_unique(v::Vector)
  d = Dict()
  for e=v
    if ! has(d,e)
      d[e] = nothing
    end
  end
  return length(d)
end


function read_data(filename::String)
  fh = open(filename)
  phrase_counts = ref(Int64)
  phrases = ref(String)
  for line=EachLine(fh)
    fields = split(line)
    push(phrase_counts, parse_int(fields[1]))
    push(phrases, fields[2])
  end
  (phrase_counts, phrases)
end

# simple counter
function counter(collection::Dict{String, Int64}, w::String)
  collection[w] = get(collection, w, 0) + 1
end

# zipper
function zipper(a::Vector, b::Vector, c::Vector, d::Vector)
  @assert length(a) == length(b) == length(c) == length(d)
  return {(a[i],b[i],c[i],d[i]) for i = 1:length(a)}
end

# general zipper
function zipper(v::Vector)
  @assert length(v) > 1
  l = length(v)
  k = length(v[1])
  for j = 2:l
    @assert length(v[j]) == k
  end
  z = { {v[j][i] for j = 1:l} for i = 1:k }
end

function sort_by_val(h::Dict{String, Int})
  # sort in descending order
  temp = {(v,k) for (k,v) = h}
  return sortr(temp)
end

function most_common(h::Dict{String, Int}, n::Int)
  if n == 0
    return []
  else
    @assert n >= 1
    return sort_by_val(h)[1:n]
  end
end
