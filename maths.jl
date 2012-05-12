# collection of utils functions written in Julia
# http://julialang.org/
# author: Ke Tran
# TODO: add verify functions
# date: May 12, 2012

function log_exponential(gamma, k)
  @assert gamma > 0
  @assert k > 0
  -1.0 * gamma * log(k)
end

function log_geometric(gamma::Float64, k::Int64)
  @assert k >= 0
  k * log(1.0 - gamma) + log(gamma)
end

function log_geometric(gamma::Float64, N::Vector{Int64})
  N * log(1.0 - gamma) + log(gamma)
end

function log_geometric_truncated(gamma::Float64, k::Int64, N::Int64)
  # return a truncated probability
  @assert 0 <= k <= N
  logp = [0:N] * log(1.0-gamma) + log(gamma)
  b = max(logp)
  logz = log( sum( exp(logp - b) ) ) + b
  logp[k+1] - logz # note k and k+1
end

function LogGeometricTruncated(gamma::Float64, N::Int64)
  # return a vector of truncated probabilities
  logprobs = [0:N] * log(1.0 - gamma) + log(gamma)
  b = max(logprobs)
  logz = log( ( sum( exp(logprobs - b) ) ) ) + b
  logprobs - logz
end

type FastDirichletMult
  alpha::Float64
  dim::Int64
  counts::Vector{Int64} # set zeros(Int64, dim) for initialization
  total::Int64

  # Constructors
  FastDirichletMult(alpha,dim,counts,total) = new(alpha,dim,counts,total)
  FastDirichletMult(alpha,dim) = FastDirichletMult(alpha, dim, zeros(Int64, dim), 0)
end

function validate(p::FastDirichletMult)
  allp(x -> x>=0, counts) && sum(counts) == total
end

function ==(p::FastDirichletMult, q::FastDirichletMult)
  (p.alpha == q.alpha) && (p.dim == q.dim) && all(p.counts == q.counts) && (p.total == q.total)
end

function !=(p::FastDirichletMult, q::FastDirichletMult)
  ! (p == q)
end

function observe(p::FastDirichletMult, k::Int64, v::Int64)
  @assert k >= 1
  p.counts[k] += v
  p.total += v
  #p
end

function log_prob(p::FastDirichletMult, k::Int64)
  # this is the result after integrating out
  # see my report, how to derive to this formula
  @assert k >= 1
  log( (p.alpha + p.counts[k]) / (p.alpha*p.dim + p.total) )
end

function log_prob_with_N(p::FastDirichletMult, k::Int64, N::Int64)
  @assert k >= 1 # remove later
  log( (p.alpha + p.counts[k]) / (p.alpha*N + p.total) )
end

# Dirichlet Multinomial
type DirichletMult
  alpha::Float64
  counts::HashTable # TODO HashTable{String, Int64}
  total::Int64

  # Constructors
  DirichletMult(alpha, counts, total) = new(alpha, counts, total)
  DirichletMult(alpha) = DirichletMult(alpha, HashTable(), 0)
end

function observe(p::DirichletMult, k, v::Int64)
  p.counts[k] = get(p.counts,k,0) + v
  p.total += v
  if p.counts[k] == 0
    del(p.counts, k)
  end
end

function prob(p::DirichletMult, k, N)
  @assert length(p.counts) <= N
  numer = p.alpha + get(p.counts,k,0)
  @assert p.total >= 0
  denom = p.alpha * N + p.total
  numer/denom
end

function log_prob(p::DirichletMult, k, N)
  log(prob(p,k,N))
end

# Fast Dirichlet Multinomial Array
# Use for POS, each word has nd possible POSs
type FastDirichletMultArray
  alpha::Float64
  nd::Int64 # number of distributions
  counts::HashTable # TODO HashTable{String, Int64}
  totals::Vector{Int64}

  FastDirichletMultArray(alpha,nd,counts,totals) = new(alpha,nd,counts,totals)
  FastDirichletMultArray(alpha,nd) = FastDirichletMultArray(alpha,nd,HashTable(),zeros(Int64,nd))
end

function observe(p::FastDirichletMultArray, i::Int64, k, v::Int64)
  if ! has(p.counts, k)
    p.counts[k] = zeros(Int64, p.nd)
  end
  c = p.counts[k]
  c[i] += v
  p.totals[i] += v
  if c[i] == 0 && sum(c) == 0
    del(p.counts, k)
  end
end

function log_probs_no_tag(p::FastDirichletMultArray, k, N::Int64)
  sum_totals = sum(p.totals)
  countsk = get(p.counts, k, zeros(Int64, p.nd))
  sum_counts = sum(countsk)
  log( (p.alpha + sum_counts) / (p.alpha*N + sum_totals) )
end

function log_probs(p::FastDirichletMultArray, k, N::Int64, tags::Vector{Int64})
  countsk = get(p.counts, k, zeros(Int64, p.nd))
  log( (p.alpha + countsk[tags]) ./ (p.alpha*N + p.totals[tags]) )
end

function log_probs_with_Ns(p::FastDirichletMultArray, k, Ns, tags::Vector{Int64})
  @assert length(Ns) == length(tags)
  countsk = get(p.counts, k, zeros(Int64, p.nd))
  log( (p.alpha + countsk[tags]) ./ (p.alpha*Ns + p.totals[tags]))
end


# this function used to pick randomly a label
# given an unnormalized log probabilities
# used for Gibbs Sampling, to pick the value of current
# sample state. In case vals has 2 elements, it's like
# fliping the coin

function sample_from_unnormalized_logs(vals::Vector{Float64})
  if length(vals) == 1
    return 1,1.0,vals[1]
  end
  b = max(vals)
  logz = log( sum(exp(vals-b)) ) + b
  probs = exp(vals-logz)
  @assert sum(probs) - 1.0 < 1e-10
  random_number = rand()
  p = 0.0
  for i=1:length(probs)
    p += probs[i]
    if random_number < p
      return i, probs[i], logz
    end
  end
  @assert false
end


