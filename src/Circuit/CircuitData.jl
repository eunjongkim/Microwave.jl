
mutable struct CircuitData{S<:Real, T<:CircuitParams} <: AbstractData
    nPoint::Int
    frequency::Vector{S}
    params::Vector{T}
    CircuitData(frequency::AbstractVector{S}, params::Vector{T}) where
        {S<:Real, T<:CircuitParams} =
        (length(frequency) == length(params))?
        new{S,T}(length(frequency), collect(frequency), params):
        error("CircuitData Error: Number of frequency points and datapoints don't match.")
end

check_frequency_identical(d1::CircuitData, d2::CircuitData, d3::CircuitData...) =
    begin
        data = [d1, d2, d3...]
        freqs = [d.frequency for d in data]
        # foldl doesn't seem to work reliably here
        # foldl(==, freqs)
        all(n -> (freqs[1] == freqs[n]), 1:length(freqs))
    end

"""
    ndatapoints(d::CircuitData{S, T}) where {S<:Real, T<:CircuitParams}
The number of datapoints for a given `CircuitData`.
"""
ndatapoints(d::CircuitData{S, T}) where {S<:Real, T<:CircuitParams} =
    length(d.frequency)

function show(io::IO, D::CircuitData{S, T}) where {S<:Real, T<:CircuitParams}
    write(io, "CircuitData{$S, $T}, ")
    write(io, "# datapoints = $(D.nPoint)\n")
end

# getindex methods for CircuitData
for p in (:Impedance, :Admittance)
    @eval getindex(D::CircuitData{S, $p{T}}, I::Int) where {S<:Real, T<:Real} =
        D.params[I].data
    @eval getindex(D::CircuitData{S, $p{T}}, I::Range) where {S<:Real, T<:Real} =
        [D.params[n].data for n in I]
    @eval getindex(D::CircuitData{S, $p{T}}, I::Vector) where {S<:Real, T<:Real} =
        [D.params[n] for n in I]
    @eval getindex(D::CircuitData{S, $p{T}}, I::Vector{Bool}) where {S<:Real,
        T<:Real} = (length(D.params) == length(I))?
        [D.params[n].data for n in Base.LogicalIndex(I)]:
        error("Length of the mask different from lenghth of the array attemped to access")
    @eval getindex(D::CircuitData{S, $p{T}}, ::Colon) where {S<:Real, T<:Real} =
        getindex(D, 1:length(D.params))
end
