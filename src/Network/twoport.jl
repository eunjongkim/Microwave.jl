# See Table 4.1 of Pozar, Microwave Engineering

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
series_network(Z::CircuitParams{T}) where {T<:Real} =
    ABCDparams([1 convert(Impedance, Z).data; 0 1])
"""
    series_network(D::CircuitData{T}) where {T<:CircuitParams}
Promote `Vector{CircuitParams}` to `Vector{ABCDparams}` assuming series
connection.
"""
series_network(Z::Vector{T}) where {T<:CircuitParams} =
    [series_network(Z[idx]) for idx in 1:length(Z)]
"""
    series_network(D::CircuitData{T}) where {T<:CircuitParams}
Promote `CircuitData` to `NetworkData{ABCDparams}` assuming series connection.
"""
series_network(D::CircuitData{S, T}; Z0=50.0) where {S<:Real, T<:CircuitParams} =
    NetworkData(D.frequency, series_network(D.params); Z0=Z0)

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
    ABCDparams([1 0; convert(Admittance, Y).data 1])
"""
    parallel_network(D::CircuitData{T}) where {T<:CircuitParams}
Promote `Vector{CircuitParams}` to `Vector{ABCDparams}` assuming parallel
connection.
"""
parallel_network(Y::Vector{T}) where {T<:CircuitParams} =
    [parallel_network(Y[idx]) for idx in 1:length(Y)]
"""
    parallel_network(D::CircuitData{T}) where {T<:CircuitParams}
Promote `CircuitData` to `NetworkData{ABCDparams}` assuming parallel connection.
"""
parallel_network(D::CircuitData{S, T}; Z0=50.0) where {S<:Real, T<:CircuitParams} =
    NetworkData(D.frequency, parallel_network(D.params); Z0=Z0)

"""
    terminated_network(Z::CircuitParams; Z0=50.0)
Promote `CircuitParams` to `Sparams` assuming termination with impedance `Z`.
```
     ┌─────────○
   ┌─┴─┐
   | Z |  port 1
   └─┬─┘
◁───┴─────────○
```
"""
function terminated_network(Z::Impedance{T}; Z0=50.0) where {T<:Number}
    d = [reflection_coefficient(Z0, convert(Impedance, Z).data) for i in 1:1,
        j in 1:1]
    return Sparams(d)
end
"""
    terminated_network(Z::Vector{T}; Z0=50.0) where {T<:CircuitParams}
Promote `Vector{CircuitParams}` to `Vector{Sparams}` assuming termination
with impedance `Z0`.
"""
terminated_network(Z::Vector{T}; Z0=50.0) where {T<:CircuitParams} =
    [terminated_network(Z[idx]; Z0=Z0) for idx in 1:length(Z)]
"""
    terminated_network(D::CircuitData{T}; Z0=50.0) where {T<:CircuitParams}
Promote `CircuitData` to `NetworkData{Sparams}` assuming terminated
connection to ground.
"""
terminated_network(D::CircuitData{S, T}; Z0=50.0) where {S<:Real, T<:CircuitParams} =
    NetworkData(D.frequency, terminated_network(D.params; Z0=Z0))

"""
    π_network(Y1::CircuitParams, Y2::CircuitParams, Y3::CircuitParams)
Promote `CircuitParams` Y1, Y2, and Y3 to `ABCDparams` assuming Π-network
configuration.
```
              ┌────┐
   ○──────┬───┤ Y3 ├───┬──────○
        ┌─┴─┐ └────┘ ┌─┴─┐
 port1  |Y1 |        |Y2 |  port2
        └─┬─┘        └─┬─┘
   ○──────┴────────────┴──────○
```
"""
function π_network(Y1::CircuitParams, Y2::CircuitParams, Y3::CircuitParams)
    _Y1, _Y2, _Y3 = [convert(Admittance, Y).data for Y in [Y1, Y2, Y3]]
    return ABCDparams([(1 + _Y2/_Y3) 1/_Y3;
        (_Y1 + _Y2 + _Y1 * _Y2/_Y3) (1 + _Y1/_Y3)])
end

"""
    π_network(Y1::Array{T, 1}, Y2::Array{S, 1}, Y3::Array{U, 1}) where
        {T<:CircuitParams, S<:CircuitParams, U<:CircuitParams}
Promote arrays of `CircuitParams` Y1, Y2, and Y3 to those of `ABCDparams`
assuming Π-network configuration.
"""
π_network(Y1::Array{T, 1}, Y2::Array{S, 1}, Y3::Array{U, 1}) where
    {T<:CircuitParams, S<:CircuitParams, U<:CircuitParams} =
    [π_network(Y1[idx], Y2[idx], Y3[idx]) for idx in 1:length(Y1)]

"""
    π_network(D1::CircuitData{T}, D2::CircuitData{S}, D3::CircuitData{U}) where
        {T<:CircuitParams, S<:CircuitParams, U<:CircuitParams}
Promote `CircuitData` D1, D2, and D3 to `NetworkData{ABCDparams}` assuming
Π-network configuration. Supported only for data with same frequency range.
"""
π_network(D1::CircuitData, D2::CircuitData, D3::CircuitData) =
    check_frequency_identical(D1, D2, D3) ?
    NetworkData(D1.frequency, π_network(D1.params, D2.params, D3.params)) :
    error("`NetworkData` can only be constructed for `CircuitData` defined in same frequencies")

"""
    t_network(Z1::CircuitParams, Z2::CircuitParams, Z3::CircuitParams)
Promote `CircuitParams` Z1, Z2, and Z3 to `ABCDparams` assuming T-network
configuration.
```
      ┌────┐       ┌────┐
 ○────┤ Z1 ├───┬───┤ Z2 ├───○
      └────┘ ┌─┴─┐ └────┘
 port1       |Z3 |      port2
             └─┬─┘
 ○─────────────┴────────────○
```
"""
function t_network(Z1::CircuitParams, Z2::CircuitParams, Z3::CircuitParams)
    _Z1, _Z2, _Z3 = [convert(Impedance, Z).data for Z in [Z1, Z2, Z3]]
    return ABCDparams([(1 + _Z1/_Z3) (_Z1 + _Z2 + _Z1 * _Z2 / _Z3);
        1/_Z3 (1 + _Z2/_Z3)])
end

"""
    t_network(D1::Array{T, 1}, D2::Array{S, 1}, D3::Array{U, 1}) where
        {T<:CircuitParams, S<:CircuitParams, U<:CircuitParams}
Promote arrays of `CircuitParams` Z1, Z2, and Z3 to those of `ABCDparams`
assuming T-network configuration.

"""
t_network(Z1::Array{T, 1}, Z2::Array{S, 1}, Z3::Array{U, 1}) where
    {T<:CircuitParams, S<:CircuitParams, U<:CircuitParams} =
    [t_network(Z1[idx], Z2[idx], Z3[idx]) for idx in 1:length(Z1)]

"""
    t_network(D1::CircuitData{T}, D2::CircuitData{S}, D3::CircuitData{U}) where
        {T<:CircuitParams, S<:CircuitParams, U<:CircuitParams}
Promote `CircuitData` D1, D2, and D3 to `NetworkData{ABCDparams}` assuming
T-network configuration. Supported only for data with same frequency range.
"""
t_network(D1::CircuitData, D2::CircuitData, D3::CircuitData) =
    check_frequency_identical(D1, D2, D3) ?
    NetworkData(D1.frequency, Tnetwork(D1.params, D2.params, D3.params)) :
    error("`NetworkData` can only be constructed for `CircuitData` defined in same frequencies")
