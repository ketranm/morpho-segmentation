import sys
import random
def gamma(params):
    sample = [random.gammavariate(a,1) for a in params]
    sample = [v/sum(sample) for v in sample]
    return sample

params = [1,2,3]
print gamma(params)
