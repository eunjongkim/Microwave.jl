export CircuitParams, Impedance, Admittance, CircuitData, ∥

abstract type CircuitParams end

mutable struct Impedance <: CircuitParams
    data::Complex{MFloat}
end

mutable struct Admittance <: CircuitParams
    data::Complex{MFloat}
end

mutable struct CircuitData{T<:CircuitParams}
    nPoint::Int
    frequency::Array{Float64, 1}
    params::Array{T, 1}
    CircuitData(frequency::Array{Float64, 1},
        data::Array{T, 1}) where {T<:CircuitParams} =
        new{T}(length(frequency), frequency, data)
end

"""
    check_frequency_identical(D1::CircuitData{T}, D2::CircuitData{T},
        D3::CircuitData{T}...) where {T<:NetworkParams}
Check if all circuit data inputs share same frequency ranges.
"""
check_frequency_identical(D1::CircuitData{T}, D2::CircuitData{T},
    D3::CircuitData{T}...) where {T<:CircuitParams} =
    all([(D1.frequency == d.frequency) for d in [D2, D3...]])

circuit_op_error = "CircuitData Error: Operations between `CircuitData` are only available between same frequency datasets"

"""
    +(param1::T, param2::T, param3::T...) where {T<:CircuitParams}
Addition of objects `T<:CircuitParams`.
- If `T` is `Impedance`, it returns the equivalent series impedance of given
impedances: Zeq = Z1 + Z2 + ⋯ + Zn
- If `T` is `Admittance` it returns the equivalent parallel admittance of given
admittances: Yeq = Y1 + Y2 + ⋯ + Yn
"""
+(param1::T, param2::T, param3::T...) where {T<:CircuitParams} =
    T(+([p.data for p in [param1, param2, param3...]]...))

"""
    -(param1::T, param2::T) where {T<:CircuitParams}
Subtraction of objects `T<:CircuitParams`.
"""
-(param1::T, param2::T) where {T<:CircuitParams} =
    T(param1.data - param2.data)
*(param1::T, param2::T) where {T<:CircuitParams} = T(param1.data * param2.data)
/(param1::T, param2::T) where {T<:CircuitParams} = T(param1.data / param2.data)
^(param::T, N::Int) where {T<:CircuitParams} = T(^(param.data, N))

"""
    ∥(param1::T, param2::T, param3::T...) where {T<:CircuitParams}
Reciprocal addition of objects `T<:CircuitParams`.
- If `T` is `Impedance`, it returns the equivalent parallel impedance of given
impedances: Zeq⁻¹ = Z1⁻¹ + Z2⁻¹ + ⋯ + Zn⁻¹
- If `T` is `Admittance` it returns the equivalent series admittance of given
admittances: Yeq⁻¹ = Y1⁻¹ + Y2⁻¹ + ⋯ + Yn⁻¹
"""
∥(param1::T, param2::T, param3::T...) where {T<:CircuitParams} =
    T(1 / +([1/p.data for p in [param1, param2, param3...]]...))

"""
    +(D1::CircuitData{T}, D2::CircuitData{T}) where {T<:CircuitParams}
Addition of multiple `CircuitData`. Supported only for data with same frequency
range.
"""
+(D1::CircuitData{T}, D2::CircuitData{T},
    D3::CircuitData{T}...) where {T<:CircuitParams} =
    check_frequency_identical(D1, D2, D3...) ?
    CircuitData(D1.frequency, +([d.params for d in [D1, D2, D3...]]...)) :
    error(circuit_op_error)

"""
    ∥(D1::CircuitData{T}, D2::CircuitData{T}) where {T<:CircuitParams}
Reciprocal addition of multiple `CircuitData`. Supported only for data with
same frequency range.
"""
∥(D1::CircuitData{T}, D2::CircuitData{T},
    D3::CircuitData{T}...) where {T<:CircuitParams} =
    check_frequency_identical(D1, D2, D3...) ?
    CircuitData(D1.frequency, .∥([d.params for d in [D1, D2, D3...]]...)) :
    error(circuit_op_error)

function show(io::IO, D::CircuitData{T}) where {T<:CircuitParams}
    write(io, "$(typeof(D)):\n")
    write(io, "\tNumber of datapoints = $(D.nPoint)\n")
end
