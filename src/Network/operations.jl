for f in (:+, :-, :*, :/), p in (:Sparams, :Yparams, :Zparams, :ABCDparams)
    # Operation between NetworkParams
    @eval ($f)(p1::($p){T}, p2::($p){T}) where {T<:Real} =
        (p1.nPort == p2.nPort)? ($p)(($f)(p1.data, p2.data)) :
        error("The number of ports must be identical in order to perform binary operations")
    @eval ($f)(p1::($p){T}, p2::($p){S}) where {T<:Real, S<:Real} =
        (p1.nPort == p2.nPort)? ($p)(($f)(promote(p1.data, p2.data)...)):
        error("The number of ports must be identical in order to perform binary operations")
end

^(param::T, N::Int) where {T<:NetworkParams} = T(^(param.data,N))

"""
    permute_ports!(D::NetworkData{S, T}, I_before::Vector{Int},
        I_after::Vector{Int}) where {S<:Real, T<:NetworkParams}
Permute port indices
"""
function permute_ports!(D::NetworkData{S, T}, I_before::Vector{Int},
    I_after::Vector{Int}) where {S<:Real, T<:NetworkParams}
    if length(unique(I_before)) != length(I_before)
        error("Error: The indices contained in `I_before` must be unique")
    end
    if length(unique(I_after)) != length(I_after)
        error("Error: The indices contained in `I_after` must be unique")
    end
    if sort(I_before) != sort(I_after)
        error("Error: The arrays `I_before` and `I_after` must contain the same set of indices")
    end
    D.ports[I_after] = D.ports[I_before]
    for n in 1:D.nPoint
        # permute rows
        D.params[n].data[I_after, :] = D.params[n].data[I_before, :]
        # permute columns
        D.params[n].data[:, I_after] = D.params[n].data[:, I_before]
    end
    return D
end

permute_ports(D::NetworkData{S, T}, I_before::Vector{Int},
    I_after::Vector{Int}) where {S<:Real, T<:NetworkParams} =
    permute_ports!(deepcopy(D), I_before, I_after)

swap_ports!(D::NetworkData{S, T}, i1::Int, i2::Int) where {S<:Real,
    T<:NetworkParams} = permutePorts!(D, [i1, i2], [i2, i1])
swap_ports(D::NetworkData{S, T}, i1::Int, i2::Int) where {S<:Real,
    T<:NetworkParams} = swap_ports!(deepcopy(D), i1, i2)
