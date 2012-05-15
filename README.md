You need the latest Julia version to run this program
To run the program
julia test.jl

Parallel for 7 languages
Tested on a Computer with 8 CPUs
the program supports #CPUs > #languages = 7

To run parallel:
@assert nprocs() > length(params)

for i=2:nprocs()
  remote_call(i, run_all, params[i-1])
end


TODO:
- parallel sampling