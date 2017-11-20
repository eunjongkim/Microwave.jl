
"""
    capacitor(freq, C)
Create a `CircuitData` for a capacitor of capacitance `C` at frequencies
specified by `freq`. It uses the formula Z(ω) = 1/(jωC) where ω=2πf.
"""
capacitor(freq::Real, C::Number) = Impedance(1/(im * (2π * freq) * C))
capacitor(freq::Vector{T}, C::Number) where {T<:Real} =
    CircuitData(freq, [capacitor(f, C) for f in freq])

"""
    inductor(freq, C)
Create a `CircuitData` for an inductor of inductance `L` at frequencies
specified by `freq`. It uses the formula Z(ω) = jωL where ω=2πf.
"""
inductor(freq::Real, L::Number) = Impedance(im * (2π * freq) * L)
inductor(freq::Vector{T}, L::Number) where {T<:Real} =
    CircuitData(freq, [inductor(f, L) for f in freq])

"""
    resistor(freq, R)
Create a `CircuitData` for a resistor of resistance `R` at frequencies
specified by `freq`. It uses the formula Z(ω) = R where ω=2πf.
"""
resistor(freq::Real, R::Number) = Impedance(R)
resistor(freq::T, R::Number) where {T<:AbstractVector} =
    CircuitData(freq, [Impedance(R) for f in collect(freq)])
