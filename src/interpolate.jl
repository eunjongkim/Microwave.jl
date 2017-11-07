using Interpolations

export interpolate_data

"""
    interpolate_data(ntwk::NetworkData{T}, freq) where {T<:NetworkParams}
Interpolate `NetworkData` at a new freqeuncy range `freq`.
"""
function interpolate_data(ntwk::NetworkData{T}, freq) where {T<:NetworkParams}
    nPort = ntwk.nPort
    d = []

    for i in 1:nPort
        e = []
        for j in 1:nPort
            itp = interpolate(ntwk[(i, j), :], BSpline(Cubic(Line())), OnGrid())
            frng = ntwk.frequency[1]:(ntwk.frequency[end]-ntwk.frequency[1])/(ntwk.nPoint-1):ntwk.frequency[end]
            sitp = scale(itp, frng)
#              sitp = scale(itp, ntwk.frequency)
            push!(e, [sitp[f] for f in freq])
        end
        push!(d, e)
    end
    params = [T(hcat([[d[i][j][n] for j in 1:nPort] for i in 1:nPort]...)) for n in 1:length(freq)]

    return NetworkData(ntwk.ports, collect(freq), params)
end

"""
    interpolate_data(cdata::CircuitData{T}, freq) where {T<:CircuitParams}
Interpolate `CircuitData` at a new freqeuncy range `freq`.
"""
function interpolate_data(cdata::CircuitData{T}, freq) where {T<:CircuitParams}
    itp = interpolate(cdata[:], BSpline(Cubic(Line())), OnGrid())
    frng = (cdata.frequency[1]):(cdata.frequency[end]-cdata.frequency[1])/(cdata.nPoint-1):(cdata.frequency[end])
    sitp = scale(itp, frng)
    return CircuitData(collect(freq), [T(sitp[f]) for f in freq])
end
