# test if the program works
# load all necessary files
load("helper.jl")
load("maths.jl")
load("config.jl")
load("wordstate.jl")
load("lexicon.jl")
load("dump_dict.jl")
load("gibbs_sampler.jl")


filename = "1984.en"
outdict = "en1984"

gold_cols = read_data(filename)
gold_tags = nothing ## TODO: revise code
hyperparameters = Dict()
seq = false
suffix = false
prefix = false
num_processes = 1
numit = 2
num_tags = 1
fix_tags = false
fix_segs = false
fix_stem = false
init_tag = "uniform"
init_seg = "whole-word"
init_stem = "first"
state0 = nothing
sep_lex_size = true
flags = nothing


# test
phrase_counts = gold_cols[1]
phrases = gold_cols[2]
gold = gold_cols[2]


println("Start training ................!")
outfile = strcat(outdict,"-out-state-1.dict")
state = run_gibbs(phrase_counts, phrases, gold, gold_tags, seq, suffix, prefix, numit, fix_tags, fix_segs, fix_stem, init_tag, init_seg, init_stem, state0, outfile, sep_lex_size)


println("Second stage................!")
num_tags = 5
init_seg = "state"
init_stem = "state"
state0 = state
outfile = strcat(outdict,"-out-state-2.dict")

state = run_gibbs(phrase_counts, phrases, gold, gold_tags, seq, suffix, prefix, numit, fix_tags, fix_segs, fix_stem, init_tag, init_seg, init_stem, state0, outfile, sep_lex_size)



println("Third stage..................!")
state0 = state
init_tag = "state"
seq = true
outfile = strcat(outdict,"-out-state-3.dict")

state = run_gibbs(phrase_counts, phrases, gold, gold_tags, seq, suffix, prefix, numit, fix_tags, fix_segs, fix_stem, init_tag, init_seg, init_stem, state0, outfile, sep_lex_size)


#println("Final stage....................!")
#state0=state
#suffix = true
#state = run_gibbs(phrase_counts, phrases, gold, gold_tags, seq, suffix, prefix, numit, fix_tags, fix_segs, fix_stem, init_tag, init_seg, init_stem, state0, outfile, sep_lex_size)
