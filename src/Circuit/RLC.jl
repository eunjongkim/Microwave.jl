export capacitor, inductor, resistor

"""
    capacitor(freq, C)
Create a `CircuitData` for a capacitor of capacitance `C` at frequencies
specified by `freq`. It uses the formula Z(ω) = 1/(jωC) where ω=2πf.
"""
capacitor(freq, C) = CircuitData(freq,
    [Impedance(1/(im * (2π * freq[idx]) * C)) for idx in 1:length(freq)])

"""
    inductor(freq, C)
Create a `CircuitData` for an inductor of inductance `L` at frequencies
specified by `freq`. It uses the formula Z(ω) = jωL where ω=2πf.
"""
inductor(freq, L) = CircuitData(freq,
    [Impedance(im * (2π * freq[idx]) * L) for idx in 1:length(freq)])

"""
    resistor(freq, R)
Create a `CircuitData` for a resistor of resistance `R` at frequencies
specified by `freq`. It uses the formula Z(ω) = R where ω=2πf.
"""
resistor(freq, R) = CircuitData(freq,
    [Impedance(R) for idx in 1:length(freq)])
