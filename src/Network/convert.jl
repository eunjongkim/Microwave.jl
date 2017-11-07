# convert(any-params, data) = convert(NetworkData{any-params}, data)
convert(::Type{T}, D::NetworkData{S}) where {T<:NetworkParams, S<:NetworkParams} =
    convert(NetworkData{T}, D)

# Conversion between general nPort parameters:
convert(::Type{NetworkData{Zparams}}, S::NetworkData{Sparams}) =
    _S_to_Z(S)
convert(::Type{NetworkData{Yparams}}, S::NetworkData{Sparams}) =
    _S_to_Y(S)
convert(::Type{NetworkData{Sparams}}, Z::NetworkData{Zparams}) =
    _Z_to_S(Z)
convert(::Type{NetworkData{Sparams}}, Y::NetworkData{Yparams}) =
    _Y_to_S(Y)
convert(::Type{NetworkData{Zparams}}, Y::NetworkData{Yparams}) =
    NetworkData(Y.ports, Y.frequency,
        [Zparams(inv(Y.params[n].data)) for n in 1:Y.nPoint])

convert(::Type{NetworkData{Yparams}}, Z::NetworkData{Zparams}) =
    NetworkData(Z.ports, Z.frequency,
        [Yparams(inv(Z.params[n].data)) for n in 1:Z.nPoint])

"""
Helper matrices related to reference impedances
"""
Z_ref(ports::Array{Port, 1}) = diagm(impedances(ports), 0)
Z_ref(D::NetworkData) = Z_ref(D.ports)
G_ref(ports::Array{Port, 1}) = diagm(1./sqrt.(abs.(impedances(ports))), 0)
G_ref(D::NetworkData) = G_ref(D.ports)

"""
Conversion from S-parameters to Z-parameters
"""
function _S_to_Z(S::NetworkData{Sparams})
    E = eye(Complex{BigFloat}, S.nPort)
    _Z_ref, _G_ref = Z_ref(S), G_ref(S)
    params = [Zparams(inv(_G_ref) * inv(E - S.params[n].data) *
        (E + S.params[n].data) * _Z_ref * _G_ref) for n in 1:S.nPoint]
    return NetworkData(S.ports, S.frequency, params)
end

"""
Conversion from S-parameters to Y-parameters
"""
function _S_to_Y(S::NetworkData{Sparams})
    E = eye(Complex{BigFloat}, S.nPort)
    _Z_ref, _G_ref = Z_ref(S), G_ref(S)
    params = [Yparams(inv(_G_ref) * inv(_Z_ref) *
        inv(E + S.params[n].data) * (E - S.params[n].data) *
        _G_ref) for n in 1:S.nPoint]
    return NetworkData(S.ports, S.frequency, params)
end

"""
Conversion from Z-parameters to S-parameters
"""
function _Z_to_S(Z::NetworkData{Zparams})
    _Z_ref, _G_ref = Z_ref(Z), G_ref(Z)
    params = [Sparams(_G_ref * (Z.params[n].data - _Z_ref) *
        inv(Z.params[n].data + _Z_ref) * inv(_G_ref)) for n in 1:Z.nPoint]
    return NetworkData(Z.ports, Z.frequency, params)
end

"""
Conversion from Y-parameters to S-parameters
"""
function _Y_to_S(Y::NetworkData{Yparams})
    E = eye(Complex{BigFloat}, Y.nPort)
    _Z_ref, _G_ref = Z_ref(Y), G_ref(Y)
    params = [Sparams(_G_ref * (E - _Z_ref * Y.params[n].data) *
        inv(E + _Z_ref * Y.params[n].data) * inv(_G_ref)) for n in 1:Y.nPoint]
    return NetworkData(Y.ports, Y.frequency, params)
end

# for two-port parameters
convert(::Type{NetworkData{Sparams}}, ABCD::NetworkData{ABCDparams}) =
    _ABCD_to_S(ABCD)
convert(::Type{NetworkData{ABCDparams}}, S::NetworkData{Sparams}) =
    _S_to_ABCD(S)

"""
Conversion from ABCD-parameters to S-parameters
"""
function _ABCD_to_S(ABCD::NetworkData{ABCDparams})
    Z₀ = impedances(ABCD)[1]
    S = Vector{Sparams}(length(ABCD.params))
    # converting ABCD matrix into scattering matrix
    for n in 1:ABCD.nPoint
        (A, B, C, D) = (ABCD[(1, 1), n], ABCD[(1, 2), n],
            ABCD[(2, 1), n], ABCD[(2, 2), n])
        S11 = (A + B / Z₀ - C * Z₀ - D) / (A + B / Z₀ + C * Z₀ + D)
        S12 = 2 * (A * D - B * C) / (A + B / Z₀ + C * Z₀ + D)
        S21 = 2 / (A + B / Z₀ + C * Z₀ + D)
        S22 = (-A + B / Z₀ - C * Z₀ + D) / (A + B / Z₀ + C * Z₀ + D)
        S[n] = Sparams([S11 S12; S21 S22])
    end
    return NetworkData(ABCD.ports, ABCD.frequency, S)
end

"""
Conversion from S-parameters to ABCD-parameters
"""
function _S_to_ABCD(S::NetworkData{Sparams})
    if S.nPort != 2
        error("Error: ABCD-parameters are defined only for 2-port networks")
    end
    if S.is_uniform == false
        error("Error: The port impedances of a ABCDparams must be uniform")
    end
    Z₀ = impedances(S)[1]
    ABCD = Vector{ABCDparams}(length(S.params))  # converting S-parameters into ABCD parameters
    for n in 1:S.nPoint
        (S11, S12, S21, S22) = (S[(1, 1), n], S[(1, 2), n],
            S[(2, 1), n], S[(2, 2), n])
        A = ((1 + S11) * (1 - S22) + S12 * S21) / (2 * S21)
        B = Z₀ * ((1 + S11) * (1 + S22) - S12 * S21) / (2 * S21)
        C = 1 / Z₀ * ((1 - S11) * (1 - S22) - S12 * S21) / (2 * S21)
        D = ((1 - S11) * (1 + S22) + S12 * S21) / (2 * S21)
        ABCD[n] = ABCDparams([A B; C D])
    end
    return NetworkData(S.ports, S.frequency, ABCD)
end
