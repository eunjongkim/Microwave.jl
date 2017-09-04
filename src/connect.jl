export cascade, terminate

function *(M1::NetworkData{ABCDparams}, M2::NetworkData{ABCDparams})
    if (M1.frequency == M2.frequency) & (M1.impedance == M2.impedance)
        nPoint = M1.nPoint
        M = zeros(Complex128, (2, 2, nPoint))
        for n in 1:nPoint
            M[:, :, n] = M1.data[:, :, n] * M2.data[:, :, n]
        end
        return NetworkData(ABCDparams, 2, nPoint, M1.impedance, M1.frequency, M)
    else
        return error("Operations between data of different
            frequencies or characteristic impedances not supported")
    end
end

function ^(ABCD::NetworkData{ABCDparams}, N::Int)
    nPoint = ABCD.nPoint
    ABCDᴺ_data = zeros(Complex128, (2, 2, nPoint))
    for n in 1:nPoint
        ABCDᴺ_data[:, :, n] = ABCD.data[:, :, n] ^ N
    end
    return NetworkData(ABCDparams, 2, nPoint, ABCD.impedance, ABCD.frequency, ABCDᴺ_data)
end

"""
Cascade a 2-port touchstone data `Data::NetworkData{T}` `N::Int` times
"""
cascade(Data::NetworkData{T}, N::Int) where {T<:TwoPortParams} =
    convert(T, convert(ABCDparams, Data) ^ N)

"""
Terminate port 2 of a two-port network `s::NetworkData{Sparams}`
with a one-port touchstone data `t::NetworkData{Sparams, 1}`

s₁₁′ = s₁₁ + s₂₁t₁₁s₁₂ / (1 - t₁₁s₂₂)
"""
function terminate(s::NetworkData{Sparams}, t::NetworkData{Sparams})
    if (s.nPort != 2) | (t.nPort != 1)
        error("Supported only for the case of a two-port network terminated by a one-port network")
    end
    if (s.frequency != t.frequency) | (s.impedance != t.impedance)
        error("Operations between data of different
            frequencies or characteristic impedances not supported")
    end

    s′_data = zeros(Complex128, (1, 1, s.nPoint))
    s′_data[1, 1, :] = (s.data[1, 1, :] + s.data[2, 1, :] .* t.data[1, 1, :]
        .* s.data[1, 2, :] ./ (1 - t.data[1, 1, :] .* s.data[2, 2, :]))
    return NetworkData(Sparams, 1, s.nPoint, s.impedance, s.frequency, s′_data)
end
"""
Method for
"""
terminate{T<:NetworkParams, S<:NetworkParams}(s::NetworkData{T},
    t::NetworkData{S}) = terminate(convert(Sparams, s), convert(Sparams, t))

function interconnect(ntwk::NetworkData{T}, k::Int, l::Int) where {T<:NetworkParams}
    
    Z = impedances(ntwk)
    ntwk_S = convert(NetworkData{Sparams}, ntwk)
    if Z[k] != Z[l]
        mismatch = NetworkData([ntwk.ports[k], ntwk.ports[l]], ntwk.frequency,
            [impedance_step(Z[k], Z[l]) for n in 1:ntwk.nPoint])
        return interconnect(_connect_S(ntwk_S, k, mismatch, 1)
    else
        return _interconnect_S(ntwk_S, k, l)
    end
end

reflection_coefficient(Z1, Z2) = (Z2 - Z1) / (Z2 + Z1)
transmission_coefficient(Z1, Z2) = 1 + reflection_coefficient(Z1, Z2)
impedance_step(Z1, Z2) =
    Sparams([reflection_coefficient(Z1, Z2) transmission_coefficient(Z2, Z1);
        transmission_coefficient(Z1, Z2) reflection_coefficient(Z2, Z1)])
"""
Interconnect two ports (assumed to have same port impedances) of a single n-port
Sparameter network:

              Sₖⱼ Sᵢₗ (1 - Sₗₖ) + Sₗⱼ Sᵢₖ (1 - Sₖₗ) + Sₖⱼ Sₗₗ Sᵢₖ + Sₗⱼ Sₖₖ Sᵢₗ
S′ᵢⱼ = Sᵢⱼ + ----------------------------------------------------------
                            (1 - Sₖₗ) (1 - Sₗₖ) - Sₖₖ Sₗₗ
"""
function _interconnect_S(ntwk::NetworkData{Sparams}, k::Int, l::Int)
    k, l = sort([k, l])
    nPort, nPoint = ntwk.nPort, ntwk.nPoint
    ports = deepcopy(ntwk.ports)
    deleteat!(ports, [k, l])  # remove ports that are interconnected
    params = Vector{Sparams}(nPoint)
    newind = vcat(1:(k-1), (k+1):(l-1), (l+1):nPort)
    for n in 1:nPoint
        tmp = zeros(Complex128, (nPort, nPort))
        S = ntwk.params[n].data
        for i in newind, j in 1:newind
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
Connect two
"""
function _connect_S(A::NetworkData{Sparams}, k::Int,
    B::NetworkData{Sparams}, l::Int)
    nA, nB = A.nPort, B.nPort
    nPoint = (A.frequency == B.frequency)? A.nPoint : error("")
    portsA, portsB = deepcopy(A.ports), deepcopy(B.ports)
    ports = vcat(portsA, portsB)
    # Create a supernetwork containing `A` and `B`
    params = Vector{Sparams}(nPoint)
    for n in 1:nPoint
        tmp = zeros(Complex128, (nPort, nPort))
        tmp[1:nA, 1:nA] = A.params[n].data
        tmp[(nA+1):(nA+nB), (nA+1):(nA+nB)] = B.params[n].data
        params[n] = Sparams(tmp)
    end
    return _interconnect_S(NetworkData(ports, A.frequency, params), k, nA + l)
end
