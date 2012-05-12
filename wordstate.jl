function spans_of_length(n::Int, k::Int)
  # get all possible k-segmentations of a word len n
  if k > n return {{}} end
  if k == 1 return {{[1,n]}} end
  ret = {}
  for split = 1:n-k+1
    for span = spans_of_length(n-split, k-1)
      shifted = {}
      for s = span
        push(shifted, s + split)
      end
      enqueue(shifted, [1, split])
      push(ret, shifted)
    end
  end
  return ret
end

function index_word(d::HashTable{String, Int}, w::String) # TODO not used
  if ! has(d,w)
    d[w] = length(d) + 1
  end
end


function sort_hash(h::HashTable{String, Int64})
  sort_array = {}
  for e = h
    push(sort_array,e)
  end
  sort(sort_array)
end

function count_word_types(phrase_counts::Vector{Int}, phrases::Vector{String})
  wc = HashTable{String, Int64}()
  @assert length(phrase_counts) == length(phrases)
  for i=1:length(phrases)
    if phrase_counts[i] < 0  continue end
    to_segment = phrase_counts[i] > 0
    words = split(phrases[i])
    for w = words
      if to_segment
        wc[w] = get(wc, w, 0) + 1
      else
        wc[w] = 0
      end
    end
  end
  sort_hash(wc)
end

function copy(x::Vector{Any})
  # copy spans
  x_copy = {}
  for e = x
    push(x_copy,copy(e))
  end
  x_copy
end

type WordState
  word::String
  freq::Int
  tag::Int
  stem_index::Int
  spans::Vector
  to_segment::Bool
  to_stem::Bool
  to_tag::Bool
end

function copy(ws::WordState)
  word = ws.word
  freq = ws.freq
  tag = ws.tag
  stem_index = ws.stem_index
  spans = copy(ws.spans)
  to_segment = ws.to_segment
  to_stem = ws.to_stem
  to_tag = ws.to_tag
  return WordState(word, freq, tag, stem_index, spans, to_segment, to_stem, to_tag)
end

function get_seg_affix(i::Int, stem_index::Int)
  if i < stem_index
    return "prefix"
  elseif i > stem_index
    return "suffix"
  else
    return "stem"
  end
end

function binfreq(f::Int) # TODO: not used
  f > 0 ? ifloor(log(f)) : 0
end

function seg_affix(ws::WordState, i::Int)
  get_seg_affix(i, ws.stem_index)
end

function segments(ws::WordState)
  # segment the word according to its spans
  map(s -> ws.word[s[1]:s[2]], ws.spans)
end

function get_last_suffix(w::String, spans::Vector, stem_index::Int)
  @assert spans[1][1] == 1
  @assert spans[length(spans)][2] == length(w)
  if stem_index < length(spans)
    s = spans[length(spans)]
    return w[s[1]:s[2]]
  else
    return ""
  end
end

function get_last_suffix(ws::WordState)
  get_last_suffix(ws.word, ws.spans, ws.stem_index)
end

function get_first_prefix(w::String, spans::Vector, stem_index::Int)
  @assert spans[1][1] == 1
  @assert spans[length(spans)][2] == length(w)
  if stem_index > 1
    s = spans[1]
    return w[s[1]:s[2]]
  else
    return ""
  end
end

function get_first_prefix(ws::WordState)
  get_first_prefix(ws.word, ws.spans, ws.stem_index)
end

function stem(ws::WordState)
  s = ws.spans[ws.stem_index]
  ws.word[s[1]:s[2]]
end

function log_prob_normalized_num_segments(ws::WordState)
  @assert ws.to_segment
  num_segs = length(ws.spans)
  log_geometric(GAMMA_NORMALIZED_NUM_SEGS_PER_WORD, num_segs)
end

function seg_to_spans(seg::Vector)
  spans = {}
  i = 1
  for s = seg
    n = length(s)
    push(spans, [i,i+n-1])
    i += n
  end
  return spans
end

