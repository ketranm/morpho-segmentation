# -*- coding: utf-8 -*-
import sys
import random
import codecs
from itertools import takewhile, izip

from features import *
from collections import defaultdict
def gamma(params):
    sample = [random.gammavariate(a,1) for a in params]
    sample = [v/sum(sample) for v in sample]
    return sample


def test():
    # define all languages
    # czech
    cs_lang = "cs"
    cs_vowel = [u'í',u'ý',u'ú',u'ů',u'é',u'á',u'ó',u'i',u'y',u'u',\
                u'e',u'ě',u'a',u'o']
    cs = lang(cs_lang,cs_vowel)
    cs_feat = feature(cs, 'oana-cs.xml')

    print cs_feat.num_words
    print cs_feat.num_stems
    d = defaultdict(set)
    for w in cs_feat.dict:
        d[cs_feat.dict[w]].add(w)

    for k, v in d.items():
        if len(v) < 2:
            del d[k]
    return d

def lpm(s):
    """
    longest prefix matching
    find the longest prefix of a set of words
    """
    return ''.join(c[0] for c in takewhile(lambda x: all(x[0] == y for y in x), izip(*s)))
    
x = test()
fk = 0
for w in x:
    tmp = x[w]
    tmp.add(w)
    stem = lpm(tmp)
    if len(w) - len(stem) > 2 and len(stem) > 2:
        print stem + "\t" + w + "\t" + str(len(w)-len(stem))
        fk += 1
print fk

s = set([1,2,3,4])
s.difference(set([1,2]))
s.remove()