const POSSIBLE_AFFIXES = ["stem","prefix","suffix"]
const RESTRICT_SEG_COUNTS = true
const RESTRICT_TYPE_TAG_COUNTS = true
const BOUNDARY_TOKEN = "~~"
const MAX_SPANS = 4
const MAX_AFFIX = 2
const MODEL_STEM_POSITION = true
const ALPHA_TAG_PRIOR = 0.1
const ALPHA_EMISSION = 1e-5
const ALPHA_TRANSITION = 1.0
const CONFLICT_STEM_PROB = 1e-2
const CONFLICT_LOG_ODDS = log(CONFLICT_STEM_PROB / (1.0 - CONFLICT_STEM_PROB))
const ALPHA_SEG = 0.1
const ALPHA_CLUSTER = .7
const GAMMA_NUM_UNIQUE_SEGS = 1.0/10
const GAMMA_SEG_LEN = 1.0/1.1
const GAMMA_NUM_SEGS_PER_WORD = 1.0/3.0
const GAMMA_AFFIX_PER_WORD = 1.0/2.0
const LOG_GEOM_TRUNC_NUM_SEGS_PER_WORD = LogGeometricTruncated(GAMMA_NUM_SEGS_PER_WORD, MAX_SPANS)
const LOG_GEOM_TRUNC_NUM_AFFIX_PER_WORD = LogGeometricTruncated(GAMMA_AFFIX_PER_WORD, MAX_AFFIX)
const PAIRWISE_SUFFIX_LOGPROB = {nothing=>log(0.3), true=>log(0.6), false=>log(0.1)}
const PAIRWISE_PREFIX_LOGPROB = {nothing=>log(0.05), true=>log(0.9), false=>log(0.05)}
const USE_STEM_LENGTH_CONSTRAINT = true
const X_GAMMA_NUM_UNIQUE_SEGS = {"stem"=>1e-4, "prefix"=>1.0/1.1, "suffix"=>1.0/1.1}
const FROZEN_RE = r"^(\d)+"
