export CircuitParams, Impedance, Admittance, CircuitData, ∥
export series_network, parallel_network, terminated_network

abstract type CircuitParams end
mutable struct Impedance <: CircuitParams
    data::Complex{BigFloat}
end
mutable struct Admittance <: CircuitParams
    data::Complex{BigFloat}
end

mutable struct CircuitData{T<:CircuitParams}
    nPoint::Int
    frequency::Array{Float64, 1}
    data::Array{T, 1}
    CircuitData(frequency::Array{Float64, 1},
        data::Array{T, 1}) where {T<:CircuitParams} =
        new{T}(length(frequency), frequency, data)
end

+(param1::T, param2::T) where {T<:CircuitParams} = T(param1.data + param2.data)
-(param1::T, param2::T) where {T<:CircuitParams} = T(param1.data - param2.data)
*(param1::T, param2::T) where {T<:CircuitParams} = T(param1.data * param2.data)
/(param1::T, param2::T) where {T<:CircuitParams} = T(param1.data / param2.data)
^(param::T, N::Int) where {T<:CircuitParams} = T(^(param.data, N))

"""
Parallel addition of objects `T<:CircuitParams`. If `T` is `Impedance`, it
returns the equivalent parallel impedance of given impedances. If `T` is
`admittance` it returns the equivalent series admittance of given admittances.
"""
function ∥(param1::T, param2::T, param3::T...) where {T<:CircuitParams}
    params = [param1, param2, param3...]
    return T(1 / +([1/p.data for p in params]...))
end

"""
Series addition of two circuit data
"""
+(D1::CircuitData{T}, D2::CircuitData{T}) where {T<:CircuitParams} =
    CircuitData(D1.frequency, +(D1.data, D2.data))

"""
Parallel addition of two circuit data
"""
∥(D1::CircuitData{T}, D2::CircuitData{T}) where {T<:CircuitParams} =
    CircuitData(D1.frequency, .∥(D1.data, D2.data))
#
# function +(D1::CircuitData{T}, D2::CircuitData{S}) where {T<:CircuitParams, S<:CircuitParams}
#     CircuitData(D1.frequency, )

function show(io::IO, D::CircuitData{T}) where {T<:CircuitParams}
    write(io, "$(typeof(D)):\n")
    write(io, "\tNumber of datapoints = $(D.nPoint)\n")
end

convert(::Type{Impedance}, Y::Admittance) = Impedance(1/Y.data)
convert(::Type{Admittance}, Z::Impedance) = Admittance(1/Z.data)

convert(::Type{T}, D::Array{S, 1}) where {T<:CircuitParams, S<:CircuitParams} =
    [convert(T, d) for d in D]
convert(::Type{T}, D::CircuitData{S}) where {T<:CircuitParams, S<:CircuitParams} =
    CircuitData(D.frequency, convert(T, D.data))


"""
Series Network
```
        ┌────┐
○───────┤ Z  ├───────○
port 1  └────┘  port 2
○────────────────────○
```
"""
series_network(Z::CircuitParams) =
    ABCDparams([1.0 convert(Impedance, Z).data; 0.0 1.0])
series_network(Z::Array{T, 1}) where {T<:CircuitParams} =
    [series_network(Z[idx]) for idx in 1:length(Z)]
series_network(D::CircuitData{T}) where {T<:CircuitParams} =
    NetworkData(D.frequency, series_network(D.data))

"""
Parallel Network
```
○──────────┬─────────○
         ┌─┴─┐
port 1   | Y |  port 2
         └─┬─┘
○──────────┴─────────○
```
"""
parallel_network(Y::CircuitParams) =
    ABCDparams([1.0 0.0; convert(Admittance, Y).data 1.0])
parallel_network(Y::Array{T, 1}) where {T<:CircuitParams} =
    [parallel_network(Y[idx]) for idx in 1:length(Y)]
parallel_network(D::CircuitData{T}) where {T<:CircuitParams} =
    NetworkData(D.frequency, parallel_network(D.data))

"""
Terminated Network
```
     ┌─────────○
   ┌─┴─┐
   | Z |  port 1
   └─┬─┘
◁───┴─────────○
```
"""
function terminated_network(Z::CircuitParams; Z0=50.0)
    d = zeros(Complex{BigFloat}, (1, 1))
    d[1, 1] = (convert(Impedance, Z).data - Z0)/(convert(Impedance, Z).data + Z0)
    return Sparams(d)
end
terminated_network(Z::Array{T, 1}; Z0=50.0) where {T<:CircuitParams} =
    [terminated_network(Z[idx]; Z0=Z0) for idx in 1:length(Z)]
terminated_network(D::CircuitData{T}; Z0=50.0) where {T<:CircuitParams} =
    NetworkData(D.frequency, terminated_network(D.data; Z0=Z0))
