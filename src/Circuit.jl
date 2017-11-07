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

"""
    check_frequency_identical(D1::CircuitData{T}, D2::CircuitData{T},
        D3::CircuitData{T}...) where {T<:NetworkParams}
Check if all circuit data inputs share same frequency ranges.
"""
check_frequency_identical(D1::CircuitData{T}, D2::CircuitData{T},
    D3::CircuitData{T}...) where {T<:CircuitParams} =
    all([(D1.frequency == d.frequency) for d in [D2, D3...]])

circuit_op_error = "CircuitData Error: Operations between `CircuitData` are available only between same frequency datasets"

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
    CircuitData(D1.frequency, +([d.data for d in [D1, D2, D3...]]...)) :
    error(circuit_op_error)

"""
    ∥(D1::CircuitData{T}, D2::CircuitData{T}) where {T<:CircuitParams}
Reciprocal addition of multiple `CircuitData`. Supported only for data with
same frequency range.
"""
∥(D1::CircuitData{T}, D2::CircuitData{T},
    D3::CircuitData{T}...) where {T<:CircuitParams} =
    check_frequency_identical(D1, D2, D3...) ?
    CircuitData(D1.frequency, .∥([d.data for d in [D1, D2, D3...]]...)) :
    error(circuit_op_error)

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
    series_network(Z::CircuitParams)
Promote `CircuitParams` to `ABCDparams` assuming series connection.
```
        ┌────┐
○───────┤ Z  ├───────○
port 1  └────┘  port 2
○────────────────────○
```
"""
series_network(Z::CircuitParams) =
    ABCDparams([1.0 convert(Impedance, Z).data; 0.0 1.0])
"""
    series_network(D::CircuitData{T}) where {T<:CircuitParams}
Promote `Vector{CircuitParams}` to `Vector{ABCDparams}` assuming series
connection.
"""
series_network(Z::Array{T, 1}) where {T<:CircuitParams} =
    [series_network(Z[idx]) for idx in 1:length(Z)]
"""
    series_network(D::CircuitData{T}) where {T<:CircuitParams}
Promote `CircuitData` to `NetworkData{ABCDparams}` assuming series connection.
"""
series_network(D::CircuitData{T}) where {T<:CircuitParams} =
    NetworkData(D.frequency, series_network(D.data))

"""
    parallel_network(Y::CircuitParams)
Promote `CircuitParams` to `ABCDparams` assuming parallel connection.
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
"""
    parallel_network(D::CircuitData{T}) where {T<:CircuitParams}
Promote `Vector{CircuitParams}` to `Vector{ABCDparams}` assuming parallel
connection.
"""
parallel_network(Y::Array{T, 1}) where {T<:CircuitParams} =
    [parallel_network(Y[idx]) for idx in 1:length(Y)]
"""
    parallel_network(D::CircuitData{T}) where {T<:CircuitParams}
Promote `CircuitData` to `NetworkData{ABCDparams}` assuming parallel connection.
"""
parallel_network(D::CircuitData{T}) where {T<:CircuitParams} =
    NetworkData(D.frequency, parallel_network(D.data))

"""
    terminated_network(Z::CircuitParams; Z0=50.0)
Promote `CircuitParams` to `Sparams` assuming terminated connection to ground.
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
    d[1, 1] = reflection_coefficient(Z0, convert(Impedance, Z).data)
    return Sparams(d)
end
"""
    terminated_network(Z::Array{T, 1}; Z0=50.0) where {T<:CircuitParams}
Promote `Vector{CircuitParams}` to `Vector{Sparams}` assuming terminated
connection to ground.
"""
terminated_network(Z::Array{T, 1}; Z0=50.0) where {T<:CircuitParams} =
    [terminated_network(Z[idx]; Z0=Z0) for idx in 1:length(Z)]
"""
    terminated_network(D::CircuitData{T}; Z0=50.0) where {T<:CircuitParams}
Promote `CircuitData` to `NetworkData{Sparams}` assuming terminated
connection to ground.
"""
terminated_network(D::CircuitData{T}; Z0=50.0) where {T<:CircuitParams} =
    NetworkData(D.frequency, terminated_network(D.data; Z0=Z0))

"""
    Πnetwork(Y1::CircuitParams, Y2::CircuitParams, Y3::CircuitParams)
```
              ┌────┐
   ○──────┬───┤ Y3 ├───┬──────○
        ┌─┴─┐ └────┘ ┌─┴─┐
 port1  |Y1 |        |Y2 |  port2
        └─┬─┘        └─┬─┘
   ○──────┴────────────┴──────○
```
"""
function Πnetwork(Y1::CircuitParams, Y2::CircuitParams, Y3::CircuitParams)
    _Y1, _Y2, _Y3 = [convert(Admittance, Y).data for Y in [Y1, Y2, Y3]]
    return ABCDparams([(1 + _Y2/_Y3) 1/_Y3;
        (_Y1 + _Y2 + _Y1 * _Y2/_Y3) (1 + _Y1/_Y3)])
end

Πnetwork(Y1::Array{T, 1}, Y2::Array{S, 1}, Y3::Array{U, 1}) where
    {T<:CircuitParams, S<:CircuitParams, U<:CircuitParams} =
    [Πnetwork(Y1[idx], Y2[idx], Y3[idx]) for idx in 1:length(Y1)]

Πnetwork(D1::CircuitData{T}, D2::CircuitData{S}, D3::CircuitData{U}) where
    {T<:CircuitParams, S<:CircuitParams, U<:CircuitParams} =
    check_frequency_identical(D1, D2, D3) ?
    NetworkData(D1.frequency, Πnetwork(D1.data, D2.data, D3.data)) :
    error("`NetworkData` can only be constructed for `CircuitData` defined in same frequencies")

"""
```
    TNetwork
      ┌────┐       ┌────┐
 ○────┤ Z1 ├───┬───┤ Z2 ├───○
      └────┘ ┌─┴─┐ └────┘
 port1       |Z3 |      port2
             └─┬─┘
 ○─────────────┴────────────○
```
"""
function Tnetwork(Z1::CircuitParams, Z2::CircuitParams, Z3::CircuitParams)
    _Z1, _Z2, _Z3 = [convert(Impedance, Z).data for Z in [Z1, Z2, Z3]]
    return ABCDparams([(1 + _Z1/_Z3) (_Z1 + _Z2 + _Z1 * _Z2 / _Z3);
        1/_Z3 (1 + _Z2/_Z3)])
end

Tnetwork(Z1::Array{T, 1}, Z2::Array{S, 1}, Z3::Array{U, 1}) where
    {T<:CircuitParams, S<:CircuitParams, U<:CircuitParams} =
    [Tnetwork(Z1[idx], Z2[idx], Z3[idx]) for idx in 1:length(Z1)]

Tnetwork(D1::CircuitData{T}, D2::CircuitData{S}, D3::CircuitData{U}) where
    {T<:CircuitParams, S<:CircuitParams, U<:CircuitParams} =
    check_frequency_identical(D1, D2, D3) ?
    NetworkData(D1.frequency, Tnetwork(D1.data, D2.data, D3.data)) :
    error("`NetworkData` can only be constructed for `CircuitData` defined in same frequencies")
