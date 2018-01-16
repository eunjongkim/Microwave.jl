for p in (:Impedance, :Admittance)
    @eval ==(p1::($p){T}, p2::($p){T}) where {T<:Real} = ==(p1.data, p2.data)
    @eval ==(p1::($p){T}, p2::($p){S}) where {T<:Real, S<:Real} =
        ==(promote(p1.data, p2.data)...)
    for f in (:+, :-, :*, :/)
        # Operation between CircuitParams
        @eval ($f)(p1::($p){T}, p2::($p){T}) where {T<:Real} =
            ($p)(($f)(p1.data, p2.data))
        @eval ($f)(p1::($p){T}, p2::($p){S}) where {T<:Real, S<:Real} =
            ($p)(($f)(promote(p1.data, p2.data)...))
            @eval ($f)(x::Number, param::($p){T}) where {T<:Real} =
            ($p)(($f)(x, param.data))
        @eval ($f)(param::($p){T}, x::Number) where {T<:Real} =
            ($p)(($f)(param.data, x))
    end
end


^(z::Impedance{T}, n::Number) where {T<:Real} = Impedance(^(z.data, n))
^(y::Admittance{T}, n::Number) where {T<:Real} = Impedance(^(y.data, n))

"""
    ∥(param1::T, param2::T, param3::T...) where {T<:CircuitParams}
Reciprocal addition of objects `T<:CircuitParams`.
- If `T` is `Impedance`, it returns the equivalent parallel impedance of given
impedances: Zeq⁻¹ = Z1⁻¹ + Z2⁻¹ + ⋯ + Zn⁻¹
- If `T` is `Admittance` it returns the equivalent series admittance of given
admittances: Yeq⁻¹ = Y1⁻¹ + Y2⁻¹ + ⋯ + Yn⁻¹
"""
∥(x1::Number, x2::Number, x3::Number...) = 1 / +([1/x for x in [x1, x2, x3...]]...)

for p in (:Impedance, :Admittance)
    @eval ∥(p1::$p, p2::$p, p3::$p...) =
    ($p)(1 / +([1/param.data for param in [p1, p2, p3...]]...))
end

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
