export connect_ports, innerconnect_ports, cascade

reflection_coefficient(Z1, Z2) = (Z2 - Z1) / (Z2 + Z1)
transmission_coefficient(Z1, Z2) = 1 + reflection_coefficient(Z1, Z2)
impedance_step(Z1, Z2) =
    Sparams([reflection_coefficient(Z1, Z2) transmission_coefficient(Z2, Z1);
        transmission_coefficient(Z1, Z2) reflection_coefficient(Z2, Z1)])

check_frequency_identical(ntwkA::NetworkData{T},
    ntwkB::NetworkData{S}) where {T<:NetworkParams, S<:NetworkParams} =
    (ntwkA.frequency == ntwkB.frequency)

check_port_impedance_identical(ntwkA::NetworkData{T}, k,
    ntwkB::NetworkData{S}, l) where {T<:NetworkParams, S<:NetworkParams} =
    (ntwkA.ports[k].impedance == ntwkA.ports[k].impedance)

function connect_ports(ntwkA::NetworkData{T}, k::Int,
    ntwkB::NetworkData{S}, l::Int) where {T<:NetworkParams, S<:NetworkParams}
    ZA, ZB = impedances(ntwkA), impedances(ntwkB)
    ntwkA_S, ntwkB_S = (convert(NetworkData{Sparams}, ntwkA),
        convert(NetworkData{Sparams}, ntwkB))

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

function innerconnect_ports(ntwk::NetworkData{T}, k::Int, l::Int) where {T<:NetworkParams}
    k, l = sort([k, l])
    Z = impedances(ntwk)
    nPort = ntwk.nPort
    ntwk_S = convert(NetworkData{Sparams}, ntwk)
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


"""
innerconnect two ports (assumed to have same port impedances) of a single n-port
S-parameter network:

              Sₖⱼ Sᵢₗ (1 - Sₗₖ) + Sₗⱼ Sᵢₖ (1 - Sₖₗ) + Sₖⱼ Sₗₗ Sᵢₖ + Sₗⱼ Sₖₖ Sᵢₗ
S′ᵢⱼ = Sᵢⱼ + ----------------------------------------------------------
                            (1 - Sₖₗ) (1 - Sₗₖ) - Sₖₖ Sₗₗ
"""
function _innerconnect_S(ntwk::NetworkData{Sparams}, k::Int, l::Int)
    k, l = sort([k, l])
    nPort, nPoint = ntwk.nPort, ntwk.nPoint
    ports = deepcopy(ntwk.ports)
    deleteat!(ports, [k, l])  # remove ports that are innerconnected
    params = Vector{Sparams}(nPoint)
    newind = vcat(1:(k-1), (k+1):(l-1), (l+1):nPort)
    for n in 1:nPoint
        tmp = zeros(Complex128, (nPort, nPort))
        S = ntwk.params[n].data
        for i in newind, j in newind
            tmp[i, j] = S[i, j] +
                (S[k, j] * S[i, l] * (1 - S[l, k]) +
                 S[l, j] * S[i, k] * (1 - S[k, l]) +
                 S[k, j] * S[l, l] * S[i, k] +
                 S[l, j] * S[k, k] * S[i, l]) /
                ((1 - S[k, l]) * (1 - S[l, k]) - S[k, k] * S[l, l])
        end
        params[n] = Sparams(tmp[newind, newind])
    end
    return NetworkData(ports, ntwk.frequency, params)
end

"""
Connect two network data specified by S parameters.
"""
function _connect_S(A::NetworkData{Sparams}, k::Int,
    B::NetworkData{Sparams}, l::Int)
    nA, nB = A.nPort, B.nPort
    nPoint = check_frequency_identical(A, B)?
         A.nPoint : error("Frequency Error: The frequency points of two network data doesn't match")
    portsA, portsB = deepcopy(A.ports), deepcopy(B.ports)
    ports = vcat(portsA, portsB)
    # Create a supernetwork containing `A` and `B`
    params = Vector{Sparams}(nPoint)
    for n in 1:nPoint
        tmp = zeros(Complex128, (nA+nB, nA+nB))
        tmp[1:nA, 1:nA] = A.params[n].data
        tmp[(nA+1):(nA+nB), (nA+1):(nA+nB)] = B.params[n].data
        params[n] = Sparams(tmp)
    end
    return _innerconnect_S(NetworkData(ports, A.frequency, params), k, nA + l)
end

"""
Cascade a 2-port touchstone data `Data::NetworkData{T}` `N::Int` times
"""
cascade(ntwk::NetworkData{ABCDparams}, N::Int) =
    NetworkData(ntwk.ports, ntwk.frequency, [p^N for p in ntwk.params])

cascade(ntwk::NetworkData{T}, N::Int) where {T<:NetworkParams} =
    convert(T, cascade(convert(ABCDparams, ntwk), N))
