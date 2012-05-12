# LexiconState
type LexiconState
  # all information of a state
  words::Dict{String, WordState}
  word_freq::Vector # word-type frequency
  counter_seg::Dict{String, Int} # counter for affixes
  x_counter_seg::Dict{String, Dict{String, Int}} # affix, segs distributed according to POS
  x_fast_distrs_seg_gt::Dict{String, FastDirichletMultArray}
  distr_type_tag::DirichletMult # tag distribution
  tokens::Union(Vector{String}, Nothing) # tokens
  word_locations::Union(Dict{String, Vector{Int}}, Nothing) # locations of words, used for POS model
  fast_distr_token_gt::Union(FastDirichletMultArray, Nothing)
  distrs_transition::Union(Vector{FastDirichletMult}, Nothing)
  USE_PAIRWISE_SUFFIXES::Bool
  USE_PAIRWISE_PREFIXES::Bool
  NUM_TAGS::Int
  VALENCE_MODEL::Int
  USE_STEM_LENGTH_CONSTRAINT::Bool
  SEPARATE_LEXICON_SIZE::Bool
end

function get_counts(words::Dict{String, WordState}, num_tags::Int)
  NUM_TAGS = num_tags
  distr_type_tag = DirichletMult(ALPHA_TAG_PRIOR) # tag distribution
  counter_seg = Dict{String, Int}() # counter for segs
  x_counter_seg = Dict{String, Dict{String, Int}}() # seg is conditioned on AFFIX
  x_fast_distrs_seg_gt = Dict{String, FastDirichletMultArray}() # Distribution of seg over POS conditioned on AFFIX
  for affix = POSSIBLE_AFFIXES
    x_counter_seg[affix] = Dict{String, Int}() # count for affix
    x_fast_distrs_seg_gt[affix] = FastDirichletMultArray(ALPHA_SEG, NUM_TAGS+1)
  end

  for (w, ws) = words
    t = ws.tag  # get tag
    if ! RESTRICT_TYPE_TAG_COUNTS || (RESTRICT_TYPE_TAG_COUNTS && ws.to_tag)
      observe(distr_type_tag, t, 1)
    end

    if ! RESTRICT_SEG_COUNTS || (RESTRICT_SEG_COUNTS && ws.to_stem)
      segs = segments(ws)
      for i=1:length(segs)
        s = segs[i]
        counter_seg[s] = get(counter_seg, s, 0) + 1
        affix = seg_affix(ws, i)
        observe(x_fast_distrs_seg_gt[affix], t, s, 1)
        x_counter_seg[affix][s] = get(x_counter_seg[affix], s, 0) + 1
      end
    end
  end
  (counter_seg, x_counter_seg, x_fast_distrs_seg_gt, distr_type_tag)
end

function get_seq_token_counts(words::Dict{String, WordState}, tokens::Vector{String}, num_tags::Int)
  # Given tokens, words, and number of valid tags
  # compute emission and transition probability
  NUM_TAGS = num_tags
  fast_distrs_token_gt = FastDirichletMultArray(ALPHA_EMISSION, NUM_TAGS+1)
  distrs_transition = map(x -> FastDirichletMult(ALPHA_TRANSITION, NUM_TAGS+1), [1:NUM_TAGS+1])
  for i =1:length(tokens)
    if i == 1 continue end # pass the first token
    w = tokens[i]
    t = (w != BOUNDARY_TOKEN ? words[w].tag :  NUM_TAGS+1) # t = NUM_TAGS + 1 if not used

    if w != BOUNDARY_TOKEN
      observe(fast_distrs_token_gt, t, w, 1) # seen word w with tag t, add to emission calculation
    end

    w_ = tokens[i-1] # previous word
    t_ =  (w_ != BOUNDARY_TOKEN ? words[w_].tag : NUM_TAGS+1)
    observe(distrs_transition[t_], t, 1) # observe transition count
  end

  return (fast_distrs_token_gt, distrs_transition)
end

function init_lexicon_state(word_freq::Vector, seq_data, gold, tag_lexicon, init_tag::String, init_seg::String, init_stem::String, num_tags, state0, sep_lex_size::Bool, use_seq_suffix::Bool, use_seq_prefix::Bool)

  words = Dict{String, WordState}()
  NUM_TAGS = num_tags
  SEPARATE_LEXICON_SIZE = sep_lex_size

  # set default values for VALENCE_MODEL and USE_STEM_LENGTH_CONSTRAINT
  VALENCE_MODEL = 0
  USE_STEM_LENGTH_CONSTRAINT = true

  if init_tag == "post" || init_tag == "gold"
    @assert tag_lexicon != nothing
  end

  if init_seg == "gold"
    @assert false
  end

  if init_stem == "gold"
    @assert init_seg == "gold"
    @assert false
  end

  for (word, freq) = word_freq
    @assert word != ""
    @assert word != BOUNDARY_TOKEN
    @assert freq >= 0
    to_freeze = matches(FROZEN_RE, word)
    to_segment = ! to_freeze
    to_stem = true
    to_tag = true

    # valid tag in [1:NUM_TAGS]
    # tag = NUM_TAGS + 1 used for start, stop state
    # tag configuration
    tag = nothing
    if init_tag == "state"
      tag = state0.words[word].tag
    elseif init_tag == "uniform"
      tag = randi(NUM_TAGS)
    else
      @assert false
    end

    # spans configuration
    spans = nothing
    if init_seg == "whole-word"
      spans = {[1, strlen(word)]}
    elseif init_seg == "state"
      spans = copy(state0.words[word].spans) # TODO: Do we need deep copy?
    else
      @assert false
    end

    # stem configuraion
    stem_index = nothing
    if init_stem == "state"
      @assert init_seg == "state"
      stem_index = state0.words[word].stem_index
    elseif init_stem == "first"
      stem_index = 1
    else
      @assert false
    end
    ws = WordState(word, freq, tag, stem_index, spans, to_segment, to_stem, to_tag)
    words[word] = ws
  end

  (counter_seg, x_counter_seg, x_fast_distrs_seg_gt, distr_type_tag) = get_counts(words, NUM_TAGS)
  tokens = seq_data
  if tokens != nothing
    word_locations = get_word_locations(tokens)
    fast_distr_token_gt, distrs_transition = get_seq_token_counts(words, tokens, NUM_TAGS)
  else
    word_locations = fast_distr_token_gt = distrs_transition = nothing
  end

  lexicon_state = LexiconState(words, word_freq, counter_seg, x_counter_seg, x_fast_distrs_seg_gt, distr_type_tag, tokens, word_locations, fast_distr_token_gt, distrs_transition, use_seq_suffix, use_seq_prefix, NUM_TAGS, VALENCE_MODEL, USE_STEM_LENGTH_CONSTRAINT, SEPARATE_LEXICON_SIZE)

  return lexicon_state
end

function get_word_locations(tokens::Vector{String})
  # return a hashtable where each key is a token
  # and its values is a vector of its possitions in text
  d = Dict{String, Vector{Int}}()
  for i=1:length(tokens)
    t = tokens[i]
    if t != BOUNDARY_TOKEN
      if ! has(d,t)
        d[t] = []
      end
      push(d[t], i)
    end
  end
  return d
end


function observe_word_state(lexicon_state::LexiconState, ws::WordState, count_::Int)
  t = ws.tag
  w = ws.word
  if ! RESTRICT_TYPE_TAG_COUNTS || (RESTRICT_TYPE_TAG_COUNTS && ws.to_tag)
    observe(lexicon_state.distr_type_tag, t, count_) # see word with pos t
  end

  if ! RESTRICT_SEG_COUNTS || (RESTRICT_SEG_COUNTS && ws.to_stem)
    segs = segments(ws)
    for i = 1:length(segs)
      s = segs[i]
      lexicon_state.counter_seg[s] = get(lexicon_state.counter_seg, s, 0) + count_
      if lexicon_state.counter_seg[s] == 0 del(lexicon_state.counter_seg, s) end
      affix = seg_affix(ws, i) # get affix
      observe(lexicon_state.x_fast_distrs_seg_gt[affix], t, s, count_) # affix conditioned on tag
      c = lexicon_state.x_counter_seg[affix]
      c[s] = get(c, s, 0) + count_
      if c[s] == 0 del(c,s) end
    end
  end

  if lexicon_state.tokens != nothing 
    for i = lexicon_state.word_locations[w]
      @assert lexicon_state.tokens[i] == w
      @assert w != BOUNDARY_TOKEN
      observe(lexicon_state.fast_distr_token_gt, t, w, count_)
      w_ = lexicon_state.tokens[i-1] # look at the previous token
      t_ = lexicon_state.NUM_TAGS + 1 # t_ = nothing
      if w_ == BOUNDARY_TOKEN
        t_ = lexicon_state.NUM_TAGS + 1 # dealing with boudaray tokens
      elseif w_ == w
        t_ = t
      else
        t_ = lexicon_state.words[w_].tag
      end
      observe(lexicon_state.distrs_transition[t_], t, count_)

      _w = lexicon_state.tokens[i+1] # loot at the next token
      _t = lexicon_state.NUM_TAGS + 1 # _t = nothing
      if _w != w
        if _w == BOUNDARY_TOKEN
          _t = lexicon_state.NUM_TAGS + 1
        elseif _w == w
          _t = t # w not added yet
        else
          _t = lexicon_state.words[_w].tag
        end
        observe(lexicon_state.distrs_transition[t], _t, count_)
      end
    end
  end
end

function add_word_state(lexicon_state::LexiconState, ws::WordState)
  w = ws.word
  @assert ! has(lexicon_state.words, w) # make sure the word is deleted before
  observe_word_state(lexicon_state, ws, 1)
  lexicon_state.words[w] = copy(ws) ## need deepcopy?
end

function remove_word(lexicon_state::LexiconState, w::String)
  ws = lexicon_state.words[w]
  observe_word_state(lexicon_state, ws, -1)
  del(lexicon_state.words, w)
  return ws
end

function to_segmented_lexicon(lexicon_state::LexiconState)
  # return dictionary of word and its segmentation
  d = Dict{String, Vector{String}}()
  for (w,ws) = lexicon_state.words
    s = segments(ws)
    d[w] = s
  end
  return d
end

# these following functions used to print some statistical info
# use to DEBUG
# can be removed
function num_prefixes_per_word(lexicon_state::LexiconState)
  d = ref(Int)
  for (w, ws) = lexicon_state.words
    if ws.to_segment
      push(d, ws.stem_index - 1) # number of prefixes
    end
  end
  return d
end

function num_suffixes_per_word(lexicon_state::LexiconState)
  d = ref(Int)
  for (w, ws) = lexicon_state.words
    if ws.to_segment
      push(d, numel(ws.spans) - ws.stem_index)
    end
  end
  return d
end

function seg_lens(lexicon_state::LexiconState)
  # number of segmentations
  d = ref(Int)
  for (w, ws) = lexicon_state.words
    if ws.to_segment
      for s = segments(ws)
        push(d, length(s))
      end
    end
  end
  return d
end

# end DEGUB mode

function normalized_num_seg(lexicon_state::LexiconState)
  # why? Actually, we do not use this
  # for debuging
  a = ref(Float64)
  for (w,ws) = lexicon_state
    push(a, length(ws.spans) / strlen(w))
  end
  return a
end

# TODO: debug
function prefixes(lexicon_state::LexiconState)
  d = ref(String)
  for (w,ws)=lexicon_state.words
    if ws.to_segment && ws.stem_index > 1
      for i=ws.spans[1:ws.stem_index-1]
        push(d, w[ i[1]:i[2] ])
      end
    end
  end
  return d
end

function num_prefix_types(lexicon_state::LexiconState)
  num_unique(prefixes(lexicon_state))
end

function suffixes(lexicon_state::LexiconState)
  d = ref(String)
  for (w,ws)=lexicon_state.words
    if ws.to_segment && ws.stem_index < length(ws.spans)
      for i= ws.spans[ws.stem_index+1:length(ws.spans)]
        push(d,w[ i[1]:i[2] ])
      end
    end
  end
  return d
end

function num_suffix_types(lexicon_state::LexiconState)
  num_unique(suffixes(lexicon_state))
end

function stems(lexicon_state::LexiconState)
  d = ref(String)
  for (w,ws)=lexicon_state.words
    if ws.to_segment
      push(d, w[ ws.spans[ws.stem_index][1] : ws.spans[ws.stem_index][2] ])
    end
  end
  return d
end

function get_affix_segment_lengths(lexicon_state::LexiconState)
  # category segments into affix classes
  d = Dict{String, Vector{Int}}()
  # do trick here, initiate d first
  for x = POSSIBLE_AFFIXES
    d[x] = ref(Int)
  end

  for (w,ws)=lexicon_state.words
    if ws.to_segment
      for i=1:length(ws.spans)
        affix = seg_affix(ws, i)
        push(d[affix], ws.spans[i][2] - ws.spans[i][1] + 1)
      end
    end
  end
  return d
end

function get_min_affix_vocab_size(lexicon_state::LexiconState, segs, stem_index::Int)
  affixes = Dict{String, Set{String}}() #  check type of Set
  for i=1:length(segs)
    s = segs[i]
    x = get_seg_affix(i, stem_index)
    if ! has(affixes, x) affixes[x] = Set{String}() end
    add(affixes[x], s)
  end

  sz = Dict{String, Int}()
  for (x,s) = affixes
    c = lexicon_state.x_counter_seg[x]
    current_size = length(c)
    num_new_types = 0
    for seg=s
      if get(c, seg, 0) == 0 num_new_types += 1 end
    end
    sz[x] = current_size + num_new_types
  end
  return sz
end

function log_prob_segment_length(k::Int)
  log_geometric(GAMMA_SEG_LEN, k-1)
end

function get_log_tag_prior(lexicon_state::LexiconState, all_possible_tags)
  d = ref(Float64)
  for t = all_possible_tags # [1:NUM_TAGS]
    push(d, log_prob(lexicon_state.distr_type_tag, t, lexicon_state.NUM_TAGS)) # TODO: NUM_TAGS + 1
  end
  return d
end

function log_token_emission(lexicon_state::LexiconState, w::String, tags)
  d = lexicon_state.fast_distr_token_gt
  @assert w != BOUNDARY_TOKEN
  @assert ! has(d.counts, w) # TODO: check type, might cause BUG
  nw = length(lexicon_state.word_locations[w])
  V = length(d.counts) # check again the original paper of Liang
  log_probs = zeros(length(tags))
  for j=1:length(tags)
    t = tags[j]
    total = d.totals[t]
    for i=1:nw
      numer = d.alpha + i - 1
      denom = d.alpha*V + total + i - 1
      log_probs[j] += log(numer/denom)
    end
  end
  return log_probs
end

function increment_transition_counts(d::Dict{Int, Dict{Int, Int}}, t_::Int, t::Int)
  #if t_ == 0 @assert t != 0 end
  if ! has(d, t_) d[t_] = Dict{Int, Int}() end
  d[t_][t] = get(d[t_],t,0) + 1
end

function log_token_trans(lexicon_state::LexiconState, w::String, t::Int)
  @assert w != BOUNDARY_TOKEN
  tc = Dict{Int, Dict{Int, Int}}()
  for i=lexicon_state.word_locations[w]
    @assert lexicon_state.tokens[i] == w # double check
    w_ = lexicon_state.tokens[i-1] # get the previous token
    t_ = lexicon_state.NUM_TAGS + 1 # t_ = nothing
    if w_ == BOUNDARY_TOKEN
      t_ = lexicon_state.NUM_TAGS + 1
    elseif w_ == w
      t_ = t
    else
      t_ = lexicon_state.words[w_].tag
    end

    increment_transition_counts(tc, t_, t)

    _w = lexicon_state.tokens[i+1] # get the next token
    if _w != w
      if _w == BOUNDARY_TOKEN
        _t = lexicon_state.NUM_TAGS + 1
      else
        _t = lexicon_state.words[_w].tag
      end

      increment_transition_counts(tc, t, _t)
    end
  end

  log_prob = 0.0
  for (t_, cc) = tc
    d = lexicon_state.distrs_transition[t_]
    N = (t_ == lexicon_state.NUM_TAGS + 1 ? lexicon_state.NUM_TAGS : lexicon_state.NUM_TAGS + 1)
    total = d.total
    for (t,n) = cc
      cnt = d.counts[t] # count
      for i = 1:n
        numer = d.alpha + cnt + i - 1
        denom = d.alpha*N + total + i - 1
        log_prob += log(numer/denom)
      end
    end
  end
  return log_prob
end

# return {nothing, true, false}
function calculate_pairwise_suffix_match(lexicon_state::LexiconState, w, spans, stem_index, neighbor)
  @assert w != neighbor
  if ! has(lexicon_state.words, neighbor)
    return nothing
  else
    w_suffix = get_last_suffix(w, spans, stem_index)
    n_suffix = get_last_suffix(lexicon_state.words[neighbor])
    m = max(strlen(w_suffix), strlen(n_suffix)) # NOTE: min or max?
    if m > 0
      w_ends = (strlen(w) >= m ? w[ strlen(w)-m+1 :] : w)
      n_ends = (strlen(neighbor) >= m ? neighbor[ strlen(neighbor)-m+1 :] : neighbor)
      if w_ends == n_ends
        return w_suffix == n_suffix
      else
        return nothing
      end
    else
      return nothing
    end
  end
end

function calculate_pairwise_prefix_match(lexicon_state::LexiconState, w::String, spans, stem_index::Int64, neighbor::String)
  @assert w != neighbor
  if ! has(lexicon_state.words, neighbor)
    return nothing
  else
    w_prefix = get_first_prefix(w, spans, stem_index)
    n_prefix = get_first_prefix(lexicon_state.words[neighbor])
    m = max(strlen(w_prefix), strlen(n_prefix))
    if m >0
      w_p = ( strlen(w) >= m ? w[1:m] : w )
      n_p = ( strlen(neighbor) >= m ? neighbor[1:m] : neighbor )
      if w_p == n_p
        return w_prefix == n_prefix
      else
        return nothing
      end
    else
      return nothing
    end
  end
end

# update at sampling one word-type
# important function, can't be wrong
# TODO: it's wrong atm, FIX now
function log_uprob_of_new_word_state_fast(lexicon_state::LexiconState, w::String, freq::Int, all_possible_tags::Vector{Int}, spans, stem_index, log_tag_probs)
  for t = all_possible_tags
    @assert t < lexicon_state.NUM_TAGS + 1 # ignore token boundary
  end
  if stem_index > MAX_AFFIX+1 || length(spans) - stem_index > MAX_AFFIX
    return fill(-Inf, length(all_possible_tags))
  end

  if lexicon_state.USE_STEM_LENGTH_CONSTRAINT
    if stem_length_violation(spans, stem_index)
      return fill(-Inf, length(all_possible_tags))
    end
  end
  @assert length(log_tag_probs) == length(all_possible_tags)

  segs = ref(String)
  unique_segs = Set{String}()
  # DEGUB: Julia hasn't supported fully UTF-8 yet
  # so I have to do some trick
  for s = spans
    try
      push(segs, w[ s[1]:s[2] ])
      add(unique_segs, w[ s[1]:s[2] ])
    catch
      # ignore for now
    end
  end
  new_unique_segs = ref(String)
  for s = unique_segs
    if get(lexicon_state.counter_seg,s,0) == 0
      push(new_unique_segs, s)
    end
  end
  min_num_segs = length(lexicon_state.counter_seg) + length(new_unique_segs) # NOTE: check to delete zero count in counter_seg! DONE
  affix_counter = Dict{String, Int}() # count number of segs for each affix
  x_new_unique_segs = Dict{String, Set{String}}()
  # initiate x_new_unique_segs
  for affix = POSSIBLE_AFFIXES
    x_new_unique_segs[affix] = Set{String}()
  end
  for i = 1:length(segs)
    affix = get_seg_affix(i, stem_index)
    affix_counter[affix] = get(affix_counter, affix, 0) + 1
    if lexicon_state.SEPARATE_LEXICON_SIZE
      if get(lexicon_state.x_counter_seg[affix], segs[i], 0) == 0
        add(x_new_unique_segs[affix], segs[i])
      end
    end
  end
 	
  log_prob_lexicon = 0.0
  if lexicon_state.SEPARATE_LEXICON_SIZE
    # TODO separate size for prefix, stem, suffix
    for affix = POSSIBLE_AFFIXES
      min_num_segs = length(lexicon_state.x_counter_seg[affix]) + length(x_new_unique_segs[affix])
      log_prob_lexicon += log_geometric(X_GAMMA_NUM_UNIQUE_SEGS[affix], min_num_segs)
    end
  else
    log_prob_lexicon += log_geometric(GAMMA_NUM_UNIQUE_SEGS, min_num_segs - 1) #TODO: -1 OR NOT
  end
  for s = new_unique_segs
  	if strlen(s)==0
  	println(w,"\t",new_unique_segs)
  	end
    log_prob_lexicon += log_prob_segment_length( strlen(s) )
  end
  
  if lexicon_state.VALENCE_MODEL == 0
    log_prob_lexicon += LOG_GEOM_TRUNC_NUM_SEGS_PER_WORD[length(spans)+1] # Critical death
  elseif lexicon_state.VALENCE_MODEL == 1
    log_prob_lexicon += LOG_GEOM_TRUNC_NUM_SEGS_PER_WORD[affix_counter["prefix"]]
    log_prob_lexicon += LOG_GEOM_TRUNC_NUM_SEGS_PER_WORD[affix_counter["suffix"]]
  else
    @assert false
  end
  log_probs_v = log_prob_lexicon + log_tag_probs
  # surface forms
  affix_min_vocab_size = get_min_affix_vocab_size(lexicon_state, segs, stem_index)
  for i = 1:length(segs)
    affix = get_seg_affix(i, stem_index)
    fast_distrs_seg_gt = lexicon_state.x_fast_distrs_seg_gt[affix]
    Ns = affix_min_vocab_size[affix]
    if affix == "stem"
      v = log_probs_no_tag(fast_distrs_seg_gt, segs[i], Ns)
      log_probs_v += v
    else
      p = log_probs(fast_distrs_seg_gt, segs[i], Ns, all_possible_tags)
      if ! (i+1 == stem_index || i == length(segs))
        for t = all_possible_tags
          observe(fast_distrs_seg_gt, t, segs[i], 1)
        end
      end
      @assert length(p) == length(all_possible_tags)
      @assert length(p) == length(log_probs_v) # TODO: remove?
      log_probs_v += p
    end
  end
  # undo cascading counts
  for i = 1:length(segs)
    affix = get_seg_affix(i, stem_index)
    fast_distrs_seg_gt = lexicon_state.x_fast_distrs_seg_gt[affix]
    if i != stem_index
      if ! (i+1 == stem_index || i == length(segs)) 
        for t = all_possible_tags
          observe(fast_distrs_seg_gt, t, segs[i], -1)
        end
      end
    end
  end
  # token-level pairwise suffix
  if lexicon_state.tokens != nothing && (lexicon_state.USE_PAIRWISE_SUFFIXES || lexicon_state.USE_PAIRWISE_PREFIXES)
    log_prob_pairwise_suffix = 0.0
    log_prob_pairwise_prefix = 0.0
    for i=lexicon_state.word_locations[w]
      w_ = lexicon_state.tokens[i-1]
      if w != w_

        if lexicon_state.USE_PAIRWISE_SUFFIXES
          suffix_match = calculate_pairwise_suffix_match(lexicon_state, w, spans, stem_index, w_)
          log_prob_pairwise_suffix += PAIRWISE_SUFFIX_LOGPROB[suffix_match]
        end

        if lexicon_state.USE_PAIRWISE_PREFIXES
          prefix_match = calculate_pairwise_prefix_match(lexicon_state, w, spans, stem_index, w_)
          log_prob_pairwise_prefix += PAIRWISE_PREFIX_LOGPROB[prefix_match]
        end

      else
        if lexicon_state.USE_PAIRWISE_SUFFIXES
          log_prob_pairwise_suffix += PAIRWISE_SUFFIX_LOGPROB[true]
        end

        if lexicon_state.USE_PAIRWISE_PREFIXES
          log_prob_pairwise_prefix += PAIRWISE_PREFIX_LOGPROB[true]
        end
      end

      _w = lexicon_state.tokens[i+1]
      if w != _w
        if lexicon_state.USE_PAIRWISE_SUFFIXES
          suffix_match = calculate_pairwise_suffix_match(lexicon_state, w, spans, stem_index, _w)
          log_prob_pairwise_suffix += PAIRWISE_SUFFIX_LOGPROB[suffix_match]
        end
        if lexicon_state.USE_PAIRWISE_PREFIXES
          prefix_match = calculate_pairwise_prefix_match(lexicon_state, w, spans, stem_index, _w)
          log_prob_pairwise_prefix += PAIRWISE_PREFIX_LOGPROB[prefix_match]
        end
      end
    end
    log_probs_v += log_prob_pairwise_suffix + log_prob_pairwise_prefix

  end
  return log_probs_v
end

function get_log_token_emissions(lexicon_state::LexiconState, w, all_possible_tags)
  @assert ! has(lexicon_state.fast_distrs_emit_gt.counts) #TODO: check the variable
  Ns = ref(Int)
  for t=all_possible_tags
    push(Ns, 1 + length(lexicon_state.t_counter_token[t]))
  end
  return log_probs_with_Ns(fast_distrs_emit_gt, w, Ns, all_possible_tags)
end

function get_tag(lexicon_state::LexiconState, w::String)
  if w == ""
    return 0
  else
    return lexicon_state.words[w].tag
  end
end

function calculate_log_tag_probs(lexicon_state::LexiconState, w::String, all_possible_tags)
  log_probs = get_log_tag_prior(lexicon_state, all_possible_tags)
  if lexicon_state.tokens != nothing
    log_emission_probs = log_token_emission(lexicon_state, w, all_possible_tags)
    log_trans_probs = ref(Float64)
    for t = all_possible_tags
      push(log_trans_probs, log_token_trans(lexicon_state, w, t))
    end
    @assert length(log_probs) == length(log_emission_probs) == length(log_trans_probs)
    log_probs += log_emission_probs += log_trans_probs
  end
  return log_probs
end

function stem_length(spans, stem_index)
  return spans[stem_index][2] - spans[stem_index][1] + 1
end

function stem_length_violation(spans::Vector, stem_index::Int)
  @assert 1 <= stem_index <= length(spans)
  stem_len = spans[stem_index][2] - spans[stem_index][1] + 1
  for i = 1:length(spans)
    if i == stem_index continue end
    sp = spans[i]
    if sp[2]-sp[1] + 1 >= stem_len
      return true
    end
  end
  return false
end

# print some statistics info
function print_stats(it::Int, lexicon_state::LexiconState)
  num_prefixes = length(lexicon_state.x_counter_seg["prefix"])
  num_suffixes = length(lexicon_state.x_counter_seg["suffix"])
  num_stems = length(lexicon_state.x_counter_seg["stem"])
  println(" iter : ", it)
  println("      top PREFIXES : ", most_common(lexicon_state.x_counter_seg["prefix"], min(10, num_prefixes)))
  println("      top SUFFIXES : ", most_common(lexicon_state.x_counter_seg["suffix"], min(10, num_suffixes)))
  println("      top STEMS : ", most_common(lexicon_state.x_counter_seg["stem"], min(5, num_stems)))
end
