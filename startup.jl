# test if the program works
# load all necessary files
load("maths.jl")
load("config.jl")
load("wordstate.jl")
load("helper.jl")
load("lexicon.jl")
load("dump_dict.jl")
load("gibbs_sampler.jl")
load("run_all.jl")


langs = {"bg","cs","en","sl","pl","sr","hu"}
data_dir = "data-sample/"
out_prefix = "model-"
out_dir = "models/"

book = "tiny-1984"
filenames = {"$(data_dir)$(book).$(lang)" for lang = langs}
outdicts = {"$(out_dir)$(out_prefix)$(lang)" for lang = langs}

gold_cols = {read_data(filename) for filename = filenames}


gold_tags = nothing
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

phrase_counts = {gold_col[1] for gold_col = gold_cols}
phrases = {gold_col[2] for gold_col = gold_cols}
gold = {gold_col[2] for gold_col = gold_cols}

outdicts_state = {"$(name)-state" for name = outdicts}
params = {Params(phrase_counts[i], phrases[i], gold[i], gold_tags, seq, suffix, prefix, numit, fix_tags, fix_segs, fix_stem, init_tag, init_seg, init_stem, num_tags, state0, outdicts_state[i], sep_lex_size) for i=1:length(filenames)}

# real run
book_full = "1984"
filenames_full = {"$(data_dir)$(book_full).$(lang)" for lang = langs}
outdicts_full = {"$(out_dir)$(out_prefix)$(lang)" for lang = langs}
outdicts_state_full = {"$(name)-state" for name = outdicts_full}
gold_cols = {read_data(filename) for filename = filenames_full}
phrase_counts = {gold_col[1] for gold_col = gold_cols}
phrases = {gold_col[2] for gold_col = gold_cols}
gold = {gold_col[2] for gold_col = gold_cols}

params_full = {Params(phrase_counts[i], phrases[i], gold[i], gold_tags, seq, suffix, prefix, numit, fix_tags, fix_segs, fix_stem, init_tag, init_seg, init_stem, num_tags, state0, outdicts_state_full[i], sep_lex_size) for i=1:length(filenames_full)}

