# convert methods for CircuitParams, Array{CircuitParams, 1}, and CircuitData

convert(::Type{Impedance}, Y::Admittance) = Impedance(1/Y.data)
convert(::Type{Admittance}, Z::Impedance) = Admittance(1/Z.data)

convert(::Type{T}, D::Array{S, 1}) where {T<:CircuitParams, S<:CircuitParams} =
    [convert(T, d) for d in D]
convert(::Type{T}, D::CircuitData{S}) where {T<:CircuitParams, S<:CircuitParams} =
    CircuitData(D.frequency, convert(T, D.params))
