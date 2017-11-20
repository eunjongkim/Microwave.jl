for f in (:+, :-, :*, :/)
    # Operation between CircuitParams
    @eval ($f)(z1::Impedance{T}, z2::Impedance{T}) where {T<:Number} =
        Impedance(($f)(z1.data, z2.data))
    @eval ($f)(z1::Impedance{T}, z2::Impedance{S}) where {T<:Number, S<:Number} =
        ($f)(promote(z1, z2)...)
    @eval ($f)(y1::Admittance{T}, y2::Admittance{T}) where {T<:Number} =
        Admittance(($f)(y1.data, y2.data))
    @eval ($f)(y1::Admittance{T}, y2::Admittance{S}) where {T<:Number, S<:Number} =
        ($f)(promote(y1, y2)...)

    # Operation between CircuitParams and numbers
    @eval ($f)(x::Number, z::Impedance{T}) where {T<:Number} =
        Impedance(($f)(x, z.data))
    @eval ($f)(z::Impedance{T}, x::Number) where {T<:Number} =
        Impedance(($f)(z.data, x))
    @eval ($f)(x::Number, y::Admittance{T}) where {T<:Number} =
        Impedance(($f)(x, y.data))
    @eval ($f)(y::Admittance{T}, x::Number) where {T<:Number} =
        Impedance(($f)(y.data, x))
end

^(z::Impedance{T}, n::Number) where {T<:Number} = Impedance(^(z.data, n))
^(y::Admittance{T}, n::Number) where {T<:Number} = Impedance(^(y.data, n))

∥(x1::Number, x2::Number, x3::Number...) = 1 / +([1/x for x in [x1, x2, x3...]]...)
"""
    ∥(param1::T, param2::T, param3::T...) where {T<:CircuitParams}
Reciprocal addition of objects `T<:CircuitParams`.
- If `T` is `Impedance`, it returns the equivalent parallel impedance of given
impedances: Zeq⁻¹ = Z1⁻¹ + Z2⁻¹ + ⋯ + Zn⁻¹
- If `T` is `Admittance` it returns the equivalent series admittance of given
admittances: Yeq⁻¹ = Y1⁻¹ + Y2⁻¹ + ⋯ + Yn⁻¹
"""
∥(p1::T, p2::T, p3::T...) where {T<:CircuitParams} =
    T(1 / +([1/p.data for p in [p1, p2, p3...]]...))

"""
    check_frequency_identical(D1::CircuitData{S, T}, D2::CircuitData{S, T},
        D3::CircuitData{S, T}...) where {S<:Real, T<:NetworkParams}
Check if all circuit data inputs share same frequency ranges.
"""
check_frequency_identical(D1::CircuitData{S, T}, D2::CircuitData{S, T},
    D3::CircuitData{S, T}...) where {S<:Real, T<:CircuitParams} =
    all([(D1.frequency == d.frequency) for d in [D2, D3...]])

op_error = "CircuitData Error: Operations between `CircuitData` are only available between same frequency datasets"

"""
    +(D1::CircuitData{S, T}, D2::CircuitData{S, T}) where {S<:Real, T<:CircuitParams}
Addition of multiple `CircuitData`. Supported only for data with same frequency
range.
"""
+(D1::CircuitData{S,T}, D2::CircuitData{S,T},
    D3::CircuitData{S,T}...) where {S<:Real, T<:CircuitParams} =
    check_frequency_identical(D1, D2, D3...) ?
    CircuitData(D1.frequency, +([d.params for d in [D1, D2, D3...]]...)) :
    error(op_error)

"""
    ∥(D1::CircuitData{S, T}, D2::CircuitData{S, T}) where {S<:Real, T<:CircuitParams}
Reciprocal addition of multiple `CircuitData`. Supported only for data with
same frequency range.
"""
∥(D1::CircuitData{S, T}, D2::CircuitData{S, T},
    D3::CircuitData{S, T}...) where {S<:Real, T<:CircuitParams} =
    check_frequency_identical(D1, D2, D3...) ?
    CircuitData(D1.frequency, .∥([d.params for d in [D1, D2, D3...]]...)) :
    error(op_error)
