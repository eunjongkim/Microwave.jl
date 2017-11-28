module Circuit

import Microwave: AbstractParams, AbstractData
import Base: +, -, *, /, ^, convert, promote_rule, show

export CircuitParams, Impedance, Admittance, CircuitData, ∥
export capacitor, inductor, resistor

abstract type CircuitParams{T<:Number} <: AbstractParams end

mutable struct Impedance{T<:Number} <: CircuitParams{T}
    data::T
end
Impedance(zd::AbstractVector{T}) where {T<:Number} = [Impedance(zd_) for zd_ in zd]

mutable struct Admittance{T<:Number} <: CircuitParams{T}
    data::T
end
Admittance(yd::AbstractVector{T}) where {T<:Number} = [Admittance(yd_) for yd_ in yd]



mutable struct CircuitData{S<:Real, T<:CircuitParams} <: AbstractData
    nPoint::Int
    frequency::Vector{S}
    params::Vector{T}
    CircuitData(frequency::AbstractVector{S},
        data::Vector{T}) where {S<:Real, T<:CircuitParams} =
        new{S,T}(length(frequency), collect(frequency), data)
end

function show(io::IO, D::CircuitData{S, T}) where {S<:Real, T<:CircuitParams}
    write(io, "$(typeof(D)):")
    write(io, "  Number of datapoints = $(D.nPoint)\n")
end

getindex(D::CircuitData{S, T}, I::Int) where {S<:Real, T<:CircuitParams} =
    D.params[I].data
getindex(D::CircuitData{S, T}, I::Range) where {S<:Real, T<:CircuitParams} =
    [D.params[n].data for n in I]
getindex(D::CircuitData{S, T}, I::Vector) where {S<:Real, T<:CircuitParams} =
    [D.params[n] for n in I]
getindex(D::CircuitData{S, T}, I::Vector{Bool}) where {S<:Real,
    T<:CircuitParams} = (length(D.params) == length(I))?
    [D.params[n].data for n in Base.LogicalIndex(I)]:
    error("Length of the mask different from lenghth of the array attemped to access")
getindex(D::CircuitData{S, T}, ::Colon) where {S<:Real, T<:CircuitParams} =
    getindex(D, 1:length(D.params))

include("convert.jl")
include("operations.jl")
include("RLC.jl")

end
