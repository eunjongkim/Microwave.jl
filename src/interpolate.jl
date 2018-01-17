using Interpolations

export interpolate_data

# """
#     interpolate_data(ntwk::NetworkData{T}, freq) where {T<:NetworkParams}
# Interpolate `NetworkData` at a new freqeuncy range `freq`.
# """
for p in (:Sparams, :Yparams, :Zparams, :ABCDparams)
    @eval interpolate_data(ntwk::NetworkData{S, ($p){T}},
        freq::AbstractVector{R}) where {S<:Real, T<:Real, R<:Real} = begin
            nPort = ntwk.nPort
            d = []
            # U = promote_type(T, S)
            for i in 1:nPort
                e = []
                for j in 1:nPort
                    Sij_itp = interpolate(((ntwk.frequency), ),
                        (ntwk[(i, j), :]), Gridded(Linear()))
            # itp = interpolate(ntwk[(i, j), :], BSpline(Cubic(Line())), OnGrid())

            # frng = ntwk.frequency[1]:(ntwk.frequency[end]-ntwk.frequency[1])/(ntwk.nPoint-1):ntwk.frequency[end]
            # sitp = scale(itp, frng)
#              sitp = scale(itp, ntwk.frequency)
                    push!(e, Sij_itp[freq])
                    # push!(e, [sitp[f] for f in freq])
                end
                push!(d, e)
            end
            params = [($p)([d[i][j][n] for i in 1:nPort, j in 1:nPort]) for n in 1:length(freq)]
            NetworkData(ntwk.ports, freq, params)
        end
end

# """
#     interpolate_data(cdata::CircuitData{T}, freq) where {T<:CircuitParams}
# Interpolate `CircuitData` at a new freqeuncy range `freq`.
# """
for p in (:Impedance, :Admittance)
    @eval interpolate_data(cdata::CircuitData{S, ($p){T}},
        freq::AbstractVector{R}) where {S<:Real, T<:Real, R<:Real} = begin
            itp = interpolate((cdata.frequency, ), cdata[:], Gridded(Linear()))
            CircuitData(freq, ($p)(itp[freq]))
        end
end
