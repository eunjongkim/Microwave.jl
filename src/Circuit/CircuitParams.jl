abstract type CircuitParams{T<:Real} <: AbstractParams end

"""
    Impedance{T<:Real} <: CircuitParams{T}
"""
mutable struct Impedance{T<:Real} <: CircuitParams{T}
    data::Complex{T}
    Impedance(z::T) where {T<:Real} = Impedance(complex(z))
end

Impedance(zd::AbstractVector{Complex{T}}) where {T<:Real} =
    [Impedance(zd_) for zd_ in zd]
Impedance(zd::AbstractVector{T}) where {T<:Real} = Impedance(Complex{T}.(zd))

"""
    Admittance{T<:Real} <: CircuitParams{T}
"""
mutable struct Admittance{T<:Real} <: CircuitParams{Real}
    data::Complex{T}
    Admittance(y::T) where {T<:Real} = Admittance(complex(y))
end

Admittance(yd::AbstractVector{Complex{T}}) where {T<:Real} =
    [Admittance(yd_) for yd_ in yd]
Admittance(yd::AbstractVector{T}) where {T<:Real} = Admittance(Complex{T}.(yd))
