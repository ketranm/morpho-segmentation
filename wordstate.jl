function spans_of_length_old(n::Int, k::Int)
  # get all possible k-segmentations of a word len n
  if k > n return {{}} end
  if k == 1 return {{[1,n]}} end
  ret = {}
  for split = 1:n-k+1
    for span = spans_of_length(n-split, k-1)
      shifted = {}
      for s in span
        push(shifted, s + split)
      end
      enqueue(shifted, [1, split])
      push(ret, shifted)
    end
  end
  return ret
end


function spans_of_length(n::Int, k::Int)
  # get all possible k-segmentations of a word len n
  if k > n return {{}} end
  if k == 1 return {{[1,n]}} end
  ret = {}
  for split = 1:n-k+1
    for span = spans_of_length_old(n-split, k-1)
      shifted = {}
      for s in span
        push(shifted, s + split)
      end
      enqueue(shifted, [1, split])
      push(ret, shifted)
    end
  end
  
  restrict_seg = {}
  for span = ret
    l = length(span)
    if l == 1
      push(restrict_seg, span)
    else
      flag = true
      for i=1:l-1
        if span[i][2]-span[i][1] == 0
          flag = false
          break
        end
      end
      if flag == true
        push(restrict_seg, span)
      end
    end
  end
  return restrict_seg
end



function index_word(d::Dict{String, Int}, w::String) # TODO not used
  if ! has(d,w)
    d[w] = length(d) + 1
  end
end


function sort_hash(h::Dict{String, Int})
  sort({e for e=h})
end

function count_word_types(phrase_counts::Vector{Int}, phrases::Vector{String})
  wc = Dict{String, Int}()
  @assert length(phrase_counts) == length(phrases)
  for i=1:length(phrases)
    if phrase_counts[i] < 0  continue end
    to_segment = phrase_counts[i] > 0
    words = split(phrases[i])
    for w = words
      wc[w] = (to_segment ? get(wc, w, 0) + 1 : 0)
    end
  end
  sort_hash(wc)
end

function copy(x::Vector{Any})
  # copy spans
  {copy(e) for e=x}
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
  cluster_id::String
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
  cluster_id = ws.cluster_id
  return WordState(word, freq, tag, stem_index, spans, to_segment, to_stem, to_tag, cluster_id)
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
  # fixed unicode issue
  cw = chars(ws.word)
  map(s -> string(cw[s[1]:s[2]]...), ws.spans)
end

function get_last_suffix(w::String, spans::Vector, stem_index::Int)
  @assert spans[1][1] == 1
  @assert spans[length(spans)][2] == strlen(w)
  stem_index < length(spans) ? (s = spans[end]; cw = chars(w); string(cw[s[1]:s[2]]...)) : ""
end

function get_last_suffix(ws::WordState)
  get_last_suffix(ws.word, ws.spans, ws.stem_index)
end

function get_first_prefix(w::String, spans::Vector, stem_index::Int)
  @assert spans[1][1] == 1
  @assert spans[length(spans)][2] == strlen(w)
  stem_index > 1 ? (s = spans[1]; cw = chars(w); string(cw[s[1]:s[2]]...)) : ""
end

function get_first_prefix(ws::WordState)
  get_first_prefix(ws.word, ws.spans, ws.stem_index)
end

function stem(ws::WordState)
  s = ws.spans[ws.stem_index]
  cw = chars(ws.word)
  string(cw[s[1]:s[2]]...)
end

function log_prob_normalized_num_segments(ws::WordState)
  @assert ws.to_segment
  num_segs = length(ws.spans)
  log_geometric(GAMMA_NORMALIZED_NUM_SEGS_PER_WORD, num_segs)
end

function seg_to_spans(seg::Vector{String})
  spans = {}
  i = 1
  for s in seg
    n = strlen(s)
    push(spans, [i,i+n-1])
    i += n
  end
  return spans
end

