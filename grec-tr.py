#!/usr/bin/python3
"""Spell out Greek letters and math symbols, so the speech engine can read them."""
import sys

SPELLED = {
    'Αα': ' alpha',
    'Ββ': ' bêta',
    'Γγ': ' gamma',
    'Δδ': ' delta',
    'Εε': ' epsilon',
    'Ζζ': ' zêta',
    'Ηη': ' êta',
    'Θθ': ' thêta',
    'Ιι': ' iota',
    'Κκ': ' kappa',
    'Λλ': ' lambda',
    'Μμ': ' mu',
    'Νν': ' nu',
    'Ξξ': ' xi',
    'Οο': ' omicron',
    'Ππ': ' pi',
    'Ρρ': ' rhô',
    'Σσ': ' sigma',
    'Ττ': ' tau',
    'Υυ': ' upsilon',
    'Φφϕ': ' phi',
    'Χχ': ' khi',
    'Ψψ': ' psi',
    'ΩωΩ': ' ôméga',  # Ω is the ohm sign, which looks like omega
    '∈': ' in ',
    '∞': ' inf ',
    '|': ' giv ',
    '∂': ' di ',
    '→': ' approaches ',
    '−': ' minus ',
    '§': ' para ',
    '∇': ' gradient ',
    '⋅': ' times ',
}
TABLE = str.maketrans({symbol: name for symbols, name in SPELLED.items() for symbol in symbols})

for line in sys.stdin:
    print(line.translate(TABLE))
