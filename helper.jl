# count number of unique elements in array
function num_unique(v::Vector)
  d = HashTable()
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
  for line=LineIterator(fh)
    fields = split(line)
    push(phrase_counts, parse_int(fields[1]))
    push(phrases, fields[2])
  end
  (phrase_counts, phrases)
end

# simple counter
function counter(collection::HashTable{String, Int64}, w::String)
  collection[w] = get(collection, w, 0) + 1
end

# zipper
function zipper(a::Vector, b::Vector, c::Vector, d::Vector)
  @assert length(a) == length(b) == length(c) == length(d)
  z = {}
  k = length(a)
  for i = 1:k
    push(z, (a[i],b[i],c[i],d[i]))
  end
  return z
end

# general zipper but with constraint on type
function zipper(v::Vector) # abstract data type T
  @assert length(v) > 1
  l = length(v)
  k = length(v[1])
  for j = 2:l
    @assert length(v[j]) == k
  end
  z = {}
  for i = 1:k
    push(z, map(x -> v[x][i], [1:l]))
  end
  return z
end

function sort_by_val(h::HashTable{String, Int})
  temp = {}
  for (k,v) = h
    push(temp, (v,k))
  end
  return sort(temp)
end

function most_common(h::HashTable{String, Int}, n::Int)
  if n == 0
    return []
  else
    @assert n >= 1
    sorted_array = sort_by_val(h)
    return reverse(sorted_array)[1:n]
  end
end
