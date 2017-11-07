using Interpolations

export interpolate_data

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

    return NetworkData(ntwk.ports, freq, params)
end
