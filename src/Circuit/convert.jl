# promotion methods for CircuitParams
for p in (:Impedance, :Admittance)
    @eval promote_rule(::Type{($p){T}}, ::Type{($p){S}}) where {T<:Real, S<:Real} =
        ($p){promote_type(T, S)}
end

# convert methods for CircuitParams, Array{CircuitParams, 1}, and CircuitData
convert(::Type{Impedance{T}}, z::Impedance{S}) where {T<:Real, S<:Real} =
    Impedance(convert(T, z.data))
convert(::Type{Admittance{T}}, y::Admittance{S}) where {T<:Real, S<:Real} =
    Admittance(convert(T, y.data))

convert(::Type{Admittance}, z::Impedance{T}) where {T<:Real} = Admittance(1/z.data)
convert(::Type{Impedance}, y::Admittance{T}) where {T<:Real} = Impedance(1/y.data)

# shortcut convert methods
convert(::Type{T}, D::Vector{S}) where {T<:CircuitParams, S<:CircuitParams} =
    [convert(T, d) for d in D]
convert(::Type{T1}, D::CircuitData{S, T2}) where {S<:Real,
    T1<:CircuitParams, T2<:CircuitParams} =
    CircuitData(D.frequency, convert(T1, D.params))
