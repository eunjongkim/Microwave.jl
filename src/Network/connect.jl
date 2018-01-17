"""
    reflection_coefficient(Z1::Number, Z2::Number)
Reflection coefficient of an impedance step from Z1 to Z2
```
     Z2 - Z1
ρ = ---------
     Z2 + Z1
```
"""
reflection_coefficient(Z1::Number, Z2::Number) = (Z2 - Z1) / (Z2 + Z1)
reflection_coefficient(Z1::Impedance, Z2::Impedance) =
    reflection_coefficient(Z1.data, Z2.data)

"""
    transmission_coefficient(Z1::Number, Z2::Number)
Transmission coefficient of an impedance step from Z1 to Z2
```
         Z2 - Z1      2 Z2
τ = 1 + --------- = ---------
         Z2 + Z1     Z2 + Z1
```
"""
transmission_coefficient(Z1::Number, Z2::Number) =
    1 + reflection_coefficient(Z1, Z2)
transmission_coefficient(Z1::Impedance, Z2::Impedance) =
    transmission_coefficient(Z1.data, Z2.data)

"""
    impedance_step(Z1, Z2)
S parameter for impedance step from Z1 to Z2.
```
S11 = reflection_coefficient(Z1, Z2), S12 = transmission_coefficient(Z2, Z1)
S21 = transmission_coefficient(Z1, Z2), S22 = reflection_coefficient(Z2, Z1)
```
"""
impedance_step(Z1, Z2) =
    Sparams([reflection_coefficient(Z1, Z2) transmission_coefficient(Z2, Z1);
        transmission_coefficient(Z1, Z2) reflection_coefficient(Z2, Z1)])

"""
    connect_ports(ntwkA::NetworkData{S1, T1}, k::Int,
        ntwkB::NetworkData{S2, T2}, l::Int) where {S1<:Real, S2<:Real,
        T1<:NetworkParams, T2<:NetworkParams}
Connect `k`-th port of `ntwkA` and `l`-th port of `ntwkB`. Note that an
impedance step is inserted between connecting ports if port impedances are not
identical.
"""
function connect_ports(ntwkA::NetworkData{S1, T1}, k::Int,
    ntwkB::NetworkData{S2, T2}, l::Int) where {S1<:Real, S2<:Real,
    T1<:NetworkParams, T2<:NetworkParams}
    ZA, ZB = impedances(ntwkA), impedances(ntwkB)
    ntwkA_S, ntwkB_S = convert(Sparams, ntwkA), convert(Sparams, ntwkB)

    if ~ check_port_impedance_identical(ntwkA_S, k, ntwkB_S, l)
        stepNetwork = NetworkData([ntwkA_S.ports[k], ntwkB_S.ports[l]],
            ntwkA_S.frequency, [impedance_step(ZA[k], ZB[l]) for n in 1:ntwkA_S.nPoint])
        ntwkA_S_matched = _connect_S(ntwkA_S, k, stepNetwork, 1)
        # renumbering of ports after attaching impedance step
        I_before, I_after = vcat(ntwkA.nPort, k:(ntwkA.nPort-1)), collect(k:(ntwkA.nPort))
        permute_ports!(ntwkA_S_matched, I_before, I_after)
        return connect_ports(ntwkA_S_matched, k, ntwkB_S, l)
    else
        return _connect_S(ntwkA_S, k, ntwkB_S, l)
    end
end

"""
    innerconnect_ports(ntwk::NetworkData{S, T}, k::Int, l::Int) where
        {S<:Real, T<:NetworkParams}
Innerconnect `k`-th and `l`-th ports of a single n-port network with following
S-parameter formula:
```
              Sₖⱼ Sᵢₗ (1 - Sₗₖ) + Sₗⱼ Sᵢₖ (1 - Sₖₗ) + Sₖⱼ Sₗₗ Sᵢₖ + Sₗⱼ Sₖₖ Sᵢₗ
S′ᵢⱼ = Sᵢⱼ + ----------------------------------------------------------
                            (1 - Sₖₗ) (1 - Sₗₖ) - Sₖₖ Sₗₗ
```
Note that an impedance step is inserted between connecting ports if port
impedances are not identical.
"""
function innerconnect_ports(ntwk::NetworkData{S, T}, k::Int, l::Int) where
    {S<:Real, T<:NetworkParams}
    k, l = sort([k, l])
    Z = impedances(ntwk)
    nPort = ntwk.nPort
    ntwk_S = convert(Sparams, ntwk)
    if ~ check_port_impedance_identical(ntwk_S, k, ntwk_S, l)
        stepNetwork = NetworkData([ntwk.ports[k], ntwk.ports[l]], ntwk.frequency,
            [impedance_step(Z[k], Z[l]) for n in 1:ntwk.nPoint])
        ntwk_S_matched = _connect_S(ntwk_S, k, stepNetwork, 1)
        # _connect_S function moves the k-th port to the nPort-th port. Need to
        # permute indices such that the k-th port impedance-matched to the l-th
        # port is located at index k.
        I_before, I_after = vcat(nPort, k:(nPort-1)), collect(k:nPort)
        permute_ports!(ntwk_S_matched, I_before, I_after)
        return innerconnect_ports(ntwk_S_matched, k, l)
    else
        return _innerconnect_S(ntwk_S, k, l)
    end
end

function _innerconnect_S(ntwk::NetworkData{S, Sparams{T}}, k::Int, l::Int) where
    {S<:Real, T<:Real}
    k, l = sort([k, l])
    nPort, nPoint = ntwk.nPort, ntwk.nPoint
    ports = deepcopy(ntwk.ports)
    deleteat!(ports, [k, l])  # remove ports that are innerconnected

    newind = vcat(1:(k-1), (k+1):(l-1), (l+1):nPort)
    params = [begin
        tmp = zeros(Complex{T}, (nPort, nPort))
        S = ntwk.params[n].data
        for i in newind, j in newind
            tmp[i, j] = S[i, j] +
                (S[k, j] * S[i, l] * (1 - S[l, k]) +
                S[l, j] * S[i, k] * (1 - S[k, l]) +
                S[k, j] * S[l, l] * S[i, k] +
                S[l, j] * S[k, k] * S[i, l]) /
                ((1 - S[k, l]) * (1 - S[l, k]) - S[k, k] * S[l, l])
        end
        Sparams(tmp[newind, newind])
    end for n in 1:nPoint]
    return NetworkData(ports, ntwk.frequency, params)
end

"""
Connect two network data specified by S parameters.
"""
function _connect_S(A::NetworkData{S1, Sparams{T1}}, k::Integer,
    B::NetworkData{S2, Sparams{T2}}, l::Integer) where {S1<:Real, S2<:Real,
    T1<:Real, T2<:Real}
    nA, nB = A.nPort, B.nPort
    nPoint = check_frequency_identical(A, B)?
         A.nPoint : error("Frequency Error: The frequency points of two network data doesn't match")
    portsA, portsB = deepcopy(A.ports), deepcopy(B.ports)
    ports = vcat(portsA, portsB)
    # Create a supernetwork containing `A` and `B`
    params = [begin
        tmp = zeros(Complex{promote_type(T1, T2)}, (nA+nB, nA+nB))
        tmp[1:nA, 1:nA] = A.params[n].data
        tmp[(nA+1):(nA+nB), (nA+1):(nA+nB)] = B.params[n].data
    Sparams(tmp)
    end for n in 1:nPoint]
    return _innerconnect_S(NetworkData(ports, A.frequency, params), k, nA + l)
end

"""
    cascade(ntwk::NetworkData{S, ABCDparams{T}}, N::Integer) where {S<:Real, T<:Number}
Cascade a 2-port network data `Data` `N` times
"""
cascade(ntwk::NetworkData{S, ABCDparams{T}}, N::Integer) where {S<:Real, T<:Real} =
    NetworkData(ntwk.ports, ntwk.frequency, [p^N for p in ntwk.params])
cascade(ntwk::NetworkData{S, T}, N::Integer) where {S<:Real, T<:NetworkParams} =
    convert(T, cascade(convert(ABCDparams, ntwk), N))

"""
    cascade(ntwk1::NetworkData, ntwk2::NetworkData, ntwk3::NetworkData...)
Cascade 2-port networks.
"""
function cascade(ntwk1::NetworkData, ntwk2::NetworkData,
    ntwk3::NetworkData...)
    ntwks = [ntwk1, ntwk2, ntwk3...]
    return NetworkData(ntwk1.ports, ntwk1.frequency,
        .*([convert(ABCDparams, ntwk).params for ntwk in ntwks]...))
end
