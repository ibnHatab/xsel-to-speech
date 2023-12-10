#!/usr/bin/python3

import re
import sys

class trialContextManager:
    def __enter__(self): pass
    def __exit__(self, *args): return True

alphabet = [
    ['Α', 	'α', 	'alpha',],
    ['Β', 	'β', 	'bêta',],
    ['Γ', 	'γ', 	'gamma',],
    ['Δ', 	'δ', 	'delta',],
    ['Ε', 	'ε', 	'epsilon',],
    ['Ζ', 	'ζ', 	'zêta',],
    ['Η', 	'η', 	'êta',],
    ['Θ', 	'θ',  	'thêta',],
    ['Ι', 	'ι', 	'iota',],
    ['Κ', 	'κ', 	'kappa',],
    ['Λ', 	'λ', 	'lambda',],
    ['Μ', 	'μ', 	'mu',],
    ['Ν', 	'ν', 	'nu',],
    ['Ξ', 	'ξ', 	'xi',],
    ['Ο', 	'ο', 	'omicron',],
    ['Π', 	'π', 	'pi',],
    ['Ρ', 	'ρ', 	'rhô',],
    ['Σ', 	'σ', 	'sigma',],
    ['Τ', 	'τ', 	'tau',],
    ['Υ', 	'υ', 	'upsilon',],
    ['Φ', 	'φ', 	'phi',],
    ['Χ', 	'χ', 	'khi',],
    ['Ψ', 	'ψ', 	'psi',],
    ['Ω', 	'ω', 	'ôméga',],
    ['Ω', 	'', 	'ôméga',],
    ['ϕ', 	'', 	'phi',],
    ['Σ', 	'', 	'sigma',],
    ['∈', 	'', 	' in ',],
    ['∞', 	'', 	' inf ',],
    ['|', 	'', 	' giv ',],
    ['∂', 	'', 	' di ',],
    ['→', 	'', 	' approaches ',],
    ['−', 	'', 	' minus ',],
]
from_upper, from_lower, to = map(list, zip(*alphabet))

rex = re.compile(r'[Α-ωϕΩ∈∞|∂→−]')

line = u'minimising that loss with respect to θω and maximising with respect to φ.ϕ,Ω'

def tr_greek(line):
    replacers = []
    for m in rex.finditer(line):
        idx = m.start(0)
        symbol = line[idx]
        with trialContextManager(): pos = from_upper.index(symbol)
        with trialContextManager(): pos = from_lower.index(symbol)
        mnemonic = to[pos]
        replacers.append((symbol, mnemonic))

    for symbol, mnemonic in replacers:
        line = line.replace(symbol, mnemonic)

    return line


for line in sys.stdin:
    print(tr_greek(line))
