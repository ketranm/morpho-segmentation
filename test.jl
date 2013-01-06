# test if the program works
# load all necessary files
load("maths.jl")
load("maths.jl")
load("config.jl")
load("wordstate.jl")
load("helper.jl")
load("lexicon.jl")
load("gibbs_sampler.jl")
load("run_all.jl")
load("blade_runner.jl")

data_dir = "data-sample/"
out_prefix = "model-"
out_dir = "models/"

book = "new_wordlist.eng"
filename = "$(data_dir)$(book)"
outdict = "$(out_dir)$(out_prefix)$(book)"
gold_cols = read_data(filename)
cluster_file = "cluster-embedding.eng"

gold_tags = nothing
hyperparameters = Dict()
seq = false
suffix = false
prefix = false
num_processes = 1
numit = 30
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
phrase_counts = gold_cols[1]
phrases = gold_cols[2]
gold = gold_cols[2]
cluster = nothing
outdicts_state = "$(outdict)-state"
params = Params(phrase_counts, cluster, phrases, gold, gold_tags, seq, suffix, prefix, numit, fix_tags, fix_segs, fix_stem, init_tag, init_seg, init_stem, num_tags, state0, outdicts_state, sep_lex_size)
run_all(params)