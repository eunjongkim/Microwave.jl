# convert methods for CircuitParams, Array{CircuitParams, 1}, and CircuitData
convert(::Type{Impedance{T}}, z::Impedance{S}) where {T<:Number, S<:Number} =
    Impedance(convert(T, z.data))
convert(::Type{Admittance{T}}, y::Admittance{S}) where {T<:Number, S<:Number} =
    Admittance(convert(T, y.data))

convert(::Type{Admittance}, z::Impedance{T}) where {T<:Number} = Admittance(1/z.data)
convert(::Type{Impedance}, y::Admittance{T}) where {T<:Number} = Impedance(1/y.data)

# shortcut convert methods
convert(::Type{T}, D::Vector{S}) where {T<:CircuitParams, S<:CircuitParams} =
    [convert(T, d) for d in D]
convert(::Type{T1}, D::CircuitData{S, T2}) where {S<:Real,
    T1<:CircuitParams, T2<:CircuitParams} =
    CircuitData(D.frequency, convert(T1, D.params))
