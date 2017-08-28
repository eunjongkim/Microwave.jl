# convert(any-params, data) = convert(NetworkData{any-params}, data)
convert{T<:TouchstoneParams, S<:TouchstoneParams}(::Type{T}, D::NetworkData{S}) =
    convert(NetworkData{T}, D)
convert{T<:TouchstoneParams}(::Type{T}, D::Touchstone) =
    convert(NetworkData{T}, D)
convert(::Type{NetworkData{Sparams}}, R::Touchstone) = _Raw_to_S(R)

"""
Conversion from `Touchstone` to `NetworkData{Sparams}`
"""
function _Raw_to_S(touchstone::Touchstone)
    nPort = touchstone.nPort
    nPoint = touchstone.nPoint
    Z₀ = touchstone.Z₀
    freq_unit = touchstone.freq_unit
    data_type = touchstone.data_type
    format_type = touchstone.format_type
    data = touchstone.data

    if data_type != "S"
        error("Data type not a scattering parameter")
    else
        # extracting frequency
        if freq_unit == "HZ"
            freq_multiplier = 1.0
        elseif freq_unit == "KHZ"
            freq_multiplier = 1.0e3
        elseif freq_unit == "MHZ"
            freq_multiplier = 1.0e6
        elseif freq_unit == "GHZ"
            freq_multiplier = 1.0e9
        elseif freq_unit == "THZ"
            freq_multiplier = 1.0e12
        end
        freq = data[1, :] * freq_multiplier

        # extracting scattering matrix
        S = zeros(Complex128, (nPort, nPort, nPoint))
        if format_type == "RI"
            for i in 1:nPort, j in 1:nPort
                idx1 = 1 + 2 * (nPort * (j - 1) + i - 1) + 1
                idx2 = 1 + 2 * (nPort * (j - 1) + i - 1) + 2
                S[i, j, :] = data[idx1, :] + im * data[idx2, :]
            end
        elseif format_type == "MA"
            for i in 1:nPort, j in 1:nPort
                idx1 = 1 + 2 * (nPort * (j - 1) + i - 1) + 1
                idx2 = 1 + 2 * (nPort * (j - 1) + i - 1) + 2
                S[i, j, :] = data[idx1, :].*exp.(im * pi / 180 * data[idx2, :])
            end
        elseif format_type == "DB"
            for i in 1:nPort, j in 1:nPort
                idx1 = 1 + 2 * (nPort * (j - 1) + i - 1) + 1
                idx2 = 1 + 2 * (nPort * (j - 1) + i - 1) + 2
                S[i, j, :] = (10.^(data[idx1, :] / 20)
                    .* exp.(im * pi / 180 * data[idx2, :]))
            end
        end
    end
    return NetworkData(Sparams, nPort, nPoint, Z₀, freq, S)
end




# for general nPort parameters:
convert(::Type{NetworkData{Zparams}}, S::NetworkData{Sparams}) =
    _S_to_Z(S)
convert(::Type{NetworkData{Yparams}}, S::NetworkData{Sparams}) =
    _S_to_Y(S)
convert(::Type{NetworkData{Sparams}}, Z::NetworkData{Zparams}) =
    _Z_to_S(Z)
convert(::Type{NetworkData{Sparams}}, Y::NetworkData{Yparams}) =
    _Y_to_S(Y)
convert(::Type{NetworkData{Zparams}}, Y::NetworkData{Yparams}) =
    NetworkData{Zparams, Y.nPort, Y.nPoint, Y.Z₀, Y.freq, _invert(Y.data)}
convert(::Type{NetworkData{Yparams}}, Z::NetworkData{Zparams}) =
    NetworkData{Yparams, Z.nPort, Z.nPoint, Z.Z₀, Z.freq, _invert(Z.data)}

"""
Matrix inversion of touchstone data
"""
function _invert(D::Array{Complex128, 3})
    nPort, _, nPoint = size(D)
    D_inv = zero(Complex128, (nPort, nPort, nPoint))
    for n in 1:nPoint
        D_inv[:, :, n] = inv(D[:, :, n])
    end
    return D_inv
end

"""
Identity matrix of `nPort`-network of `nPoint` datapoints
"""
function _identity(nPort::Integer, nPoint::Integer)
    E = zeros(Complex128, (nPort, nPort, nPoint))
    for n in 1:nPoint
        E[:, :, n] = eye(nPort)
    end
    return E
end
"""
Identity matrix similar to the given NetworkData
"""
_identity{T<:TouchstoneParams}(D::NetworkData{T}) = _identity(D.nPort, .nPoint)

"""
Conversion from S-parameters to Z-parameters
"""
function _S_to_Z(S::NetworkData{Sparams})
    E = _identity(S)
    nPort, nPoint, Z₀ = S.nPort, S.nPoint, S.Z₀
    Z_data = zeros(Complex128, (nPort, nPort, nPoint))
    for n in 1:nPoint
        Z_data[:, :, n] = inv(E[:, :, n] - S.data[:, :, n]) * (E[:, :, n] + S.data[:, :, n]) * Z₀
    end
    return NetworkData(Zparams, nPort, nPoint, Z₀, S.freq, Z_data)
end

"""
Conversion from S-parameters to Y-parameters
"""
function _S_to_Y(S::TouchstoneParams{Sparams})
    E = _identity(S)
    nPort, nPoint, Z₀ = S.nPort, S.nPoint, S.Z₀
    Y_data = zeros(Complex128, (nPort, nPort, nPoint))
    for n in 1:nPoint
        Y_data[:, :, n] = 1 / Z₀ * inv(E[:, :, n] + S[:, :, n]) * (E[:, :, n] - S[:, :, n])
    end
    return NetworkData(Yparams, nPort, nPoint, Z₀, S.freq, Y_data)
end

"""
Conversion from Z-parameters to S-parameters
"""
function _Z_to_S(Z::NetworkData{Sparams})
    E = _identity(Z)
    nPort, nPoint, Z₀ = Z.nPort, Z.nPoint, Z.Z₀
    S_data = zeros(Complex128, (nPort, nPort, nPoint))
    for n in 1:nPoint
        S_data[:, :, n] = (Z[:, :, n]/Z₀ - E[:, :, n]) * inv(Z[:, :, n]/Z₀ + E[:, :, n])
    end
    return NetworkData(Sparams, nPort, nPoint, Z₀, Z.freq, S_data)
end

"""
Conversion from Y-parameters to S-parameters
"""
function _Y_to_S(Y::NetworkData{Sparams})
    E = _identity(Y)
    nPort, nPoint, Z₀ = Y.nPort, Y.nPoint, Y.Z₀
    S_data = zeros(Complex128, (nPort, nPort, nPoint))
    for n in 1:nPoint
        S_data[:, :, n] = (E[:, :, n] - Z₀ * Y[:, :, n]) * inv(E[:, :, n] + Z₀ * Y[:, :, n])
    end
    return NetworkData(Sparams, nPort, nPoint, Z₀, Y.freq, S_data)
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
    nPoint = ABCD.nPoint
    freq = ABCD.freq
    Z₀ = ABCD.Z₀
    S = zeros(Complex128, (2, 2, nPoint))
    # converting abcd matrix into scattering matrix
    for n in 1:nPoint
        (A, B, C, D) = (ABCD.data[1, 1, n], ABCD.data[1, 2, n],
            ABCD.data[2, 1, n], ABCD.data[2, 2, n])
        S[1, 1, n] = (A + B / Z₀ - C * Z₀ - D) / (A + B / Z₀ + C * Z₀ + D)
        S[1, 2, n] = 2 * (A * D - B * C) / (A + B / Z₀ + C * Z₀ + D)
        S[2, 1, n] = 2 / (A + B / Z₀ + C * Z₀ + D)
        S[2, 2, n] = (-A + B / Z₀ - C * Z₀ + D) / (A + B / Z₀ + C * Z₀ + D)
    end
    return NetworkData(Sparams, 2, nPoint, Z₀, freq, S)
end

"""
Conversion from S-parameters to ABCD-parameters
"""
function _S_to_ABCD(S::NetworkData{Sparams})
    if S.nPort != 2
        error("Touchstone Error: ABCD-parameters are defined only for 2-port networks")
    end
    nPoint = S.nPoint
    freq = S.freq
    Z₀ = S.Z₀

    ABCD = zeros(Complex128, (2, 2, nPoint))    # converting S-parameters into ABCD parameters
    for n in 1:nPoint
        (S11, S12, S21, S22) = (S.data[1, 1, n], S.data[1, 2, n],
            S.data[2, 1, n], S.data[2, 2, n])
        ABCD[1, 1, n] = ((1 + S11) * (1 - S22) + S12 * S21) / (2 * S21)
        ABCD[1, 2, n] = Z₀ * ((1 + S11) * (1 + S22) - S12 * S21) / (2 * S21)
        ABCD[2, 1, n] = 1 / Z₀ * ((1 - S11) * (1 - S22) - S12 * S21) / (2 * S21)
        ABCD[2, 2, n] = ((1 - S11) * (1 + S22) + S12 * S21) / (2 * S21)
    end
    return NetworkData(ABCDparams, 2, nPoint, Z₀, freq, ABCD)
end
