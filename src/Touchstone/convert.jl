convert(::Type{Sparams}, raw::TouchstoneData) = _Raw_to_S(raw)

"""
Conversion from `TouchstoneData` to `NetworkData{Sparams}`
"""
function _Raw_to_S(touchstone::TouchstoneData)
    nPort = touchstone.nPort
    nPoint = touchstone.nPoint
    Z0 = touchstone.impedance
    freq_unit = touchstone.freq_unit
    data_type = touchstone.data_type
    format_type = touchstone.format_type
    data = touchstone.data

    ports = [Port(Z0) for n in 1:nPort]
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

        if format_type == "RI"
            params = __touchstone_sparams_ri(nPort, nPoint, data)
        elseif format_type == "MA"
            params = __touchstone_sparams_ma(nPort, nPoint, data)
        elseif format_type == "DB"
            params = __touchstone_sparams_db(nPort, nPoint, data)
        end
    end
    return NetworkData(ports, freq, params)
end

function __touchstone_sparams_ri(nPort, nPoint, data)
    params = [[begin
            idx1 = 1 + 2 * (nPort * (j - 1) + i - 1) + 1
            idx2 = 1 + 2 * (nPort * (j - 1) + i - 1) + 2
            data[idx1, n] + im * data[idx2, n]
        end for i in 1:nPort, j in 1:nPort] for n in 1:nPoint]
    return Sparams(params)
end

function __touchstone_sparams_ma(nPort, nPoint, data)
    params = [[begin
            idx1 = 1 + 2 * (nPort * (j - 1) + i - 1) + 1
            idx2 = 1 + 2 * (nPort * (j - 1) + i - 1) + 2
            data[idx1, n] * exp(im * π / 180 * data[idx2, n])
        end for i in 1:nPort, j in 1:nPort] for n in 1:nPoint]
    return Sparams(params)
end

function __touchstone_sparams_db(nPort, nPoint, data)
    params = [[begin
            idx1 = 1 + 2 * (nPort * (j - 1) + i - 1) + 1
            idx2 = 1 + 2 * (nPort * (j - 1) + i - 1) + 2
            10^(data[idx1, n]/20) * exp(im * π/180 * data[idx2, n])
        end for i in 1:nPort, j in 1:nPort] for n in 1:nPoint]
    return Sparams(params)
end
