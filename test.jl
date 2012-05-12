# test if the program works
# load all necessary files
load("helper.jl")
load("maths.jl")
load("config.jl")
load("wordstate.jl")
load("lexicon.jl")
load("gibbs_sampler.jl")
load("dump_dict.jl")


filename = "1984.en"
gold_cols = read_data(filename)
gold_tags = nothing ## TODO: revise code
hyperparameters = HashTable()
seq = false
suffix = false
prefix = false
num_processes = 2
numit = 50
num_tags = 1
fix_tags = false
fix_segs = false
fix_stem = false
init_tag = "uniform"
init_seg = "whole-word"
init_stem = "first"
state0 = nothing
outfile = "en1984"
sep_lex_size = true
flags = nothing


# TEST
phrase_counts = gold_cols[1]
phrases = gold_cols[2]
gold = gold_cols[2]


println("Start training ................!")
state = run_gibbs(phrase_counts, phrases, gold, gold_tags, seq, suffix, prefix, numit, fix_tags, fix_segs, fix_stem, init_tag, init_seg, init_stem, state0, outfile, sep_lex_size)

dump_dict(state, strcat(outfile,"-out-state-1.dict"))

println("Second stage................!")
num_tags = 5
init_seg = "state"
init_stem = "state"
state0 = state
state = run_gibbs(phrase_counts, phrases, gold, gold_tags, seq, suffix, prefix, numit, fix_tags, fix_segs, fix_stem, init_tag, init_seg, init_stem, state0, outfile, sep_lex_size)

dump_dict(state, strcat(outfile,"-out-state-2.dict"))


println("Third stage..................!")
state0 = state
init_tag = "state"
seq = true
state = run_gibbs(phrase_counts, phrases, gold, gold_tags, seq, suffix, prefix, numit, fix_tags, fix_segs, fix_stem, init_tag, init_seg, init_stem, state0, outfile, sep_lex_size)

dump_dict(state, strcat(outfile,"-out-state-3.dict"))


#println("Final stage....................!")
#state0=state
#suffix = true
#state = run_gibbs(phrase_counts, phrases, gold, gold_tags, seq, suffix, prefix, numit, fix_tags, fix_segs, fix_stem, init_tag, init_seg, init_stem, state0, outfile, sep_lex_size)