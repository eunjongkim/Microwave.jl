# convert(any-params, data) = convert(TouchstoneData{any-params}, data)
convert{T<:TouchstoneParams, S<:TouchstoneParams}(::Type{T}, D::TouchstoneData{S}) =
    convert(TouchstoneData{T}, D)
convert{T<:TouchstoneParams}(::Type{T}, D::RawTouchstone) =
    convert(TouchstoneData{T}, D)

convert(::Type{TouchstoneData{Sparams}}, Raw::RawTouchstone) = _Raw_to_S(Raw)
convert(::Type{TouchstoneData{Sparams}}, ABCD::TouchstoneData{ABCDparams}) =
    _ABCD_to_S(ABCD)

convert(::Type{TouchstoneData{ABCDparams}}, S::TouchstoneData{Sparams}) =
    _S_to_ABCD(S)
# conversion from Yparams, Zparams to Sparams : TODO


function _Raw_to_S(touchstone::RawTouchstone)
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
    return TouchstoneData(Sparams, nPort, nPoint, Z₀, freq, S)
end



"""
Conversion from ABCD-parameters to S-parameters
"""
function _ABCD_to_S(ABCD::TouchstoneData{ABCDparams})
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
    return TouchstoneData(Sparams, 2, nPoint, Z₀, freq, S)
end

"""
Conversion from S parameters to ABCD parameters
"""
function _S_to_ABCD(S::TouchstoneData{Sparams})
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
    return TouchstoneData(ABCDparams, 2, nPoint, Z₀, freq, ABCD)
end
