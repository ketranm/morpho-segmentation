function print_distr(p::DirichletMult)
  for (k,v) = p.counts
    println("tag $(k):\t", v/p.total)
  end
end

function print_tags(lexicon_state::LexiconState)
  fh = open("tags.txt","w")
  words = lexicon_state.words
  for (w,ws) = words
    write(fh, "$(ws.tag)\t$(w)\n")
  end
  close(fh)
end

function run_gibbs(phrase_counts::Vector{Int}, phrases::Vector{String}, gold, gold_tags, seq::Bool, use_seq_suffix::Bool, use_seq_prefix::Bool, numit::Int, fix_tags::Bool, fix_segs::Bool, fix_stem::Bool, init_tag::String, init_seg::String, init_stem::String, num_tags::Int, state0, outfile::String, sep_lex_size) # flags?
  wordcounts = count_word_types(phrase_counts, phrases)
  (post_lexicon, tag_mapping) = (nothing, nothing)
  seq_data = (seq ? phrases : ref(String))

  # construct new state
  state = init_lexicon_state(wordcounts, seq_data, gold, post_lexicon, init_tag, init_seg, init_stem, num_tags, state0, sep_lex_size, use_seq_suffix, use_seq_prefix)

  for it = 1:numit
    wordcounts_shuffled = wordcounts
    wordcounts_shuffled = shuffle(wordcounts)
    println("len of wordcounts:\t",length(wordcounts))
    for (w,freq) = wordcounts_shuffled
      old_ws = remove_word(state,w)
      to_segment = old_ws.to_segment
      to_stem = old_ws.to_stem
      to_tag = old_ws.to_tag
      all_possible_spans = nothing
      if fix_segs || (! to_segment)
        all_possible_spans = {old_ws.spans}
      else # TODO: add flags option
        all_possible_spans = {}
        for k = 1:MAX_SPANS
          if strlen(w) >=k 
            append!(all_possible_spans, spans_of_length(strlen(w),k)) 
          else
          break
          end
        end
      end
      if fix_tags || (! to_tag)
        all_possible_tags = old_ws.tag
      else
        all_possible_tags = [1:state.NUM_TAGS]
      end

      log_tag_probs = (length(all_possible_tags) > 1 ? calculate_log_tag_probs(state, w, all_possible_tags) : fill(0.0, length(all_possible_tags)))
      # HAVEN'T USE MULTI_PROCESSING YET
      temp = {}
      if ! to_stem || fix_stem
        @assert ! to_segment || fix_segs
        @assert length(all_possible_spans) == 1
        for s = all_possible_spans
          for j=old_ws.stem_index
            push(temp, (log_uprob_of_new_word_state_fast(state, w, freq, all_possible_tags, s, j, log_tag_probs),s,j))
          end
        end
      else
        for s = all_possible_spans
          for j=1:length(s)
            push(temp, (log_uprob_of_new_word_state_fast(state, w, freq, all_possible_tags, s, j, log_tag_probs),s,j))
          end
        end
      end

      nt = length(all_possible_tags)
      # considering all hypothesis
      log_unnormalized_posterior = ref(Float64)
      spans = {}
      tags = ref(Int)
      stem_indices = ref(Int)
      for (p,s,j) = temp
        for k = 1:nt
          push(log_unnormalized_posterior, p[k])
          push(spans, s)
          push(tags, all_possible_tags[k])
          push(stem_indices, j)
        end
      end
      (ind, prob, logz) = sample_from_unnormalized_logs(log_unnormalized_posterior)
      @assert ind >= 1
      chosen_spans = spans[ind]
      chosen_tag = tags[ind]
      chosen_stem_index = stem_indices[ind]
      @assert ! has(state.words,w) #TODO delete this line
      new_ws = WordState(w,freq,chosen_tag,chosen_stem_index,chosen_spans,old_ws.to_segment,old_ws.to_stem,old_ws.to_tag)
      add_word_state(state, new_ws)
    end # for wordcounts
    print_stats(it, state)
    dump_dict(state, outfile) # write out dictionary
    #print_distr(state.distr_type_tag)
    print_tags(state)
  end # numit
  return state
end

type Params
  phrase_counts::Vector{Int}
  phrases::Vector{String}
  gold::Vector{String}
  gold_tags::Nothing
  seq::Bool
  use_suffix::Bool
  use_prefix::Bool
  numit::Int
  fix_tags::Bool
  fix_segs::Bool
  fix_stem::Bool
  init_tag::String
  init_seg::String
  init_stem::String
  num_tags::Int
  state0
  outfile::String
  sep_lex_size::Bool
end

function run_gibbs(params::Params)
  run_gibbs(params.phrase_counts, params.phrases, params.gold, params.gold_tags, params.seq, params.use_suffix, params.use_prefix, params.numit, params.fix_tags, params.fix_segs, params.fix_stem, params.init_tag, params.init_seg, params.init_stem, params.num_tags, params.state0, params.outfile, params.sep_lex_size)
end
