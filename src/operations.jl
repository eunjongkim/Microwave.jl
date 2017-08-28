export cascade, terminate

function *(M1::NetworkData{ABCDparams}, M2::NetworkData{ABCDparams})
    if (M1.freq == M2.freq) & (M1.Z₀ == M2.Z₀)
        nPoint = M1.nPoint
        M = zeros(Complex128, (2, 2, nPoint))
        for n in 1:nPoint
            M[:, :, n] = M1.data[:, :, n] * M2.data[:, :, n]
        end
        return NetworkData(ABCDparams, 2, nPoint, M1.Z₀, M1.freq, M)
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
    return NetworkData(ABCDparams, 2, nPoint, ABCD.Z₀, ABCD.freq, ABCDᴺ_data)
end

"""
Cascade a 2-port touchstone data `Data::NetworkData{T}` `N::Int` times
"""
cascade{T<:TouchstoneParams}(Data::NetworkData{T}, N::Int) =
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
    if (s.freq != t.freq) | (s.Z₀ != t.Z₀)
        error("Operations between data of different
            frequencies or characteristic impedances not supported")
    end

    s′_data = zeros(Complex128, (1, 1, s.nPoint))
    s′_data[1, 1, :] = (s.data[1, 1, :] + s.data[2, 1, :] .* t.data[1, 1, :]
        .* s.data[1, 2, :] ./ (1 - t.data[1, 1, :] .* s.data[2, 2, :]))
    return NetworkData(Sparams, 1, s.nPoint, s.Z₀, s.freq, s′_data)
end
"""
Method for 
"""
terminate{T<:TouchstoneParams, S<:TouchstoneParams}(s::NetworkData{T},
    t::NetworkData{S}) = terminate(convert(Sparams, s), convert(Sparams, t))
