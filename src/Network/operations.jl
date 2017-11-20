
function +(param1::T, param2::T) where {T<:NetworkParams}
    if param1.nPort == param2.nPort
        return T(param1.data + param2.data)
    else
        error("The number of ports must be identical in order to perform binary operations")
    end
end

function -(param1::T, param2::T) where {T<:NetworkParams}
    if param1.nPort == param2.nPort
        return T(param1.data - param2.data)
    else
        error("The number of ports must be identical in order to perform binary operations")
    end
end

function *(param1::T, param2::T) where {T<:NetworkParams}
    if param1.nPort == param2.nPort
        return T(param1.data * param2.data)
    else
        error("The number of ports must be identical in order to perform binary operations")
    end
end

^(param::T, N::Int) where {T<:NetworkParams} = T(^(param.data,N))


"""
Permute port indices
"""
function permute_ports!(D::NetworkData{T}, I_before::Vector{Int},
    I_after::Vector{Int}) where {T<:NetworkParams}
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

permute_ports(D::NetworkData{T}, I_before::Vector{Int},
    I_after::Vector{Int}) where {T<:NetworkParams} =
    permute_ports!(deepcopy(D), I_before, I_after)

swap_ports!(D::NetworkData{T}, i1::Int, i2::Int) where {T<:NetworkParams} =
    permutePorts!(D, [i1, i2], [i2, i1])
swap_ports(D::NetworkData{T}, i1::Int, i2::Int) where {T<:NetworkParams} =
    swap_ports!(deepcopy(D), i1, i2)
