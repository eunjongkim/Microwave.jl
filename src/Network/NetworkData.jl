<<<<<<< current

"""
    NetworkData{S<:Real, T<:NetworkParams}
"""
mutable struct NetworkData{S<:Real, T<:NetworkParams} <: AbstractData
    nPort::Integer
    nPoint::Integer
    ports::Vector{Port}
    frequency::Vector{S}
    params::Vector{T}
    function NetworkData(ports::Vector{Port}, frequency::AbstractVector{S},
        params::Vector{T}) where {S<:Real, T<:NetworkParams}
        nPoint = length(frequency)
        nPort = length(ports)
        if (length(params) != nPoint) | (length(frequency) != nPoint)
            error("NetworkData Error: the number of data points doesn't match with number of frequency points")
        end
        if ~all(n -> (nPort == params[n].nPort), 1:nPoint)
            error("NetworkData Error: the number of ports in params doesn't match with `nPort`")
        end

        if T<:TwoPortParams
            if is_uniform(ports) == false
                error("TwoPortParams Error: two-port parameters are defined only for uniform port impedances")
            end
        end
        new{S, T}(nPort, nPoint, ports, frequency, params)
    end
end

is_uniform(ntwk::NetworkData{S, T}) where {S<:Real, T<:NetworkParams} =
    is_uniform(ntwk.ports)
is_two_port(ntwk::NetworkData{S, T}) where {S<:Real, T<:NetworkParams} =
    (ntwk.nPort == 2)

check_frequency_identical(ntwkA::NetworkData, ntwkB::NetworkData,
    ntwkC::NetworkData...) = begin
    ntwks = [ntwkA, ntwkB, ntwkC...]
    freqs = [ntwk.frequency for ntwk in ntwks]
    # foldl doesn't seem to work reliably here
    # foldl(==, freqs)
    all(n -> (freqs[1] == freqs[n]), 1:length(freqs))
    end

check_port_impedance_identical(ntwkA::NetworkData{S1, T1}, k,
    ntwkB::NetworkData{S2, T2}, l) where {S1<:Real, S2<:Real, T1<:NetworkParams,
    T2<:NetworkParams} = (ntwkA.ports[k].Z0 == ntwkB.ports[k].Z0)


"""
    NetworkData(frequency, params; port_impedance=50.0)
Convenience constructor for creating a `NetworkData` object of uniform port
impedances.
"""
NetworkData(frequency::AbstractVector{S}, params::Vector{T};
    Z0=50.0) where {S<:Real, T<:NetworkParams} =
    NetworkData([Port(Z0) for n in 1:params[1].nPort], frequency, params)

"""
    show(io::IO, D::NetworkData{T}) where {T<:NetworkParams}
Pretty-printing of `NetworkData`.
"""
function show(io::IO, D::NetworkData{S, T}) where {S<:Real, T<:NetworkParams}
    write(io, "$(D.nPort)-port $(typeof(D)):\n")
    write(io, "  # datapoints = $(D.nPoint)\n")
    write(io, "  Port Informaton:\n")
    for (n, p) in enumerate(D.ports)
        write(io, "    Port $(n) → (index = $(p.index), Z0 = Impedance($(p.Z0.data)))\n")
    end
end

impedances(D::NetworkData) = impedances(D.ports)

"""
`getindex` methods for `NetworkData{T<:NetworkParams}`. The first input argument
in the square bracket must be a 2-integer tuple (i, j) denoting which element of
parameter to get. The second input argument is either a scalar integer, Range,
integer vector, mask, or colon(:) that determines which datapoint to choose.
i.e., `D[(i, j), n]` returns the n-th data of parameter Tᵢⱼ
where T∈{S,Y,Z,ABCD,...}.
"""
getindex(D::NetworkData{S, T}, I1::Tuple{Integer, Integer},
    I2::Integer) where {S<:Real, T<:NetworkParams} = D.params[I2].data[I1...]
getindex(D::NetworkData{S, T}, I1::Tuple{Integer, Integer},
    I2::Range) where {S<:Real, T<:NetworkParams} = [D.params[n].data[I1...] for n in I2]
getindex(D::NetworkData{S, T}, I1::Tuple{Integer, Integer},
    I2::Vector) where {S<:Real, T<:NetworkParams} =
    [D.params[n].data[I1...] for n in I2]
getindex(D::NetworkData{S, T}, I1::Tuple{Integer, Integer},
    I2::Vector{Bool}) where {S<:Real, T<:NetworkParams} =
    (length(D.params) == length(I2))?
    [D.params[n].data[I1...] for n in Base.LogicalIndex(I2)]:
    error("Length of the mask different from lenghth of the array attemped to access")
getindex(D::NetworkData{S, T}, I1::Tuple{Integer, Integer},
    I2::BitArray{1}) where {S<:Real, T<:NetworkParams} =
    getindex(D, I1, collect(I2))
getindex(D::NetworkData{S, T}, I1::Tuple{Integer, Integer},
    I2::Colon) where {S<:Real, T<:NetworkParams} = getindex(D, I1, 1:length(D.params))
getindex(D::NetworkData{S, T}, I1::Tuple{Integer, Integer}) where {S<:Real, T<:NetworkParams} =
    getindex(D, I1, :)
# setindex!: TODO?
#
=======
export Port, NetworkData, impedances, swap_ports!, permute_ports!



"""
    NetworkData{T<:NetworkParams}
"""
mutable struct NetworkData{T<:NetworkParams}
    nPort::Int
    nPoint::Int
    is_uniform::Bool
    ports::Array{Port, 1}
    frequency::Array{Float64, 1}
    params::Array{T, 1}
    function NetworkData(ports::Array{Port, 1}, frequency,
        params::Array{T,1}) where {T<:NetworkParams}
        nPoint = length(frequency)
        nPort = length(ports)
        Z₀₁ = ports[1].impedance
        if all(n -> (Z₀₁ == ports[n].impedance), 1:nPort)
            is_uniform = true
        else
            is_uniform = false
        end
        if (length(params) != nPoint) | (length(frequency) != nPoint)
            error("NetworkData Error: the number of data points doesn't match with number of frequency points")
        end
        if ~all(n -> (nPort == params[n].nPort), 1:nPoint)
            error("NetworkData Error: the number of ports in params doesn't match with `nPort`")
        end

        if T<:TwoPortParams
            # This tested by inner constructor for TwoPortParams
            # if nPort != 2
            #     error("TwoPortParams Error: the number of ports must be equal to 2 for `TwoPortParams`")
            # end
            if is_uniform == false
                error("TwoPortParams Error: two-port parameters are defined only for uniform port impedances")
            end
        end
        new{T}(nPort, nPoint, is_uniform, ports, frequency, params)
    end
end

"""
    NetworkData(frequency, params; port_impedance=50.0)
Convenience constructor for creating a `NetworkData` object of uniform port
impedances.
"""
NetworkData(frequency, params; impedance::Impedance=Impedance(50.0+0.0im)) =
    NetworkData([Port(impedance) for n in 1:params[1].nPort], frequency, params)

"""
    show(io::IO, D::NetworkData{T}) where {T<:NetworkParams}
Pretty-printing of `NetworkData`.
"""
function show(io::IO, D::NetworkData{T}) where {T<:NetworkParams}
    write(io, "$(D.nPort)-port $(typeof(D)):\n")
    write(io, "\tNumber of datapoints = $(D.nPoint)\n")
    write(io, "\tPort Informaton:\n")
    for (n, p) in enumerate(D.ports)
        write(io, "\t\tPort $(n) → (global index = $(p.indPort), Z₀ = $(p.impedance))\n")
    end
end

impedances(ports::Vector{Port{T}}) where  = [p.impedance for p in ports]
impedances(D::NetworkData) = impedances(D.ports)

"""
`getindex` methods for `NetworkData{T<:NetworkParams}`. The first input argument
in the square bracket must be a 2-integer tuple (i, j) denoting which element of
parameter to get. The second input argument is either a scalar integer, Range,
integer vector, mask, or colon(:) that determines which datapoint to choose.
i.e., `D[(i, j), n]` returns the n-th data of parameter Tᵢⱼ
where T∈{S,Y,Z,ABCD,...}.
"""
getindex(D::NetworkData{T}, I1::Tuple{Int, Int},
    I2::Int) where {T<:NetworkParams} = D.params[I2].data[I1...]
getindex(D::NetworkData{T}, I1::Tuple{Int, Int},
    I2::Range) where {T<:NetworkParams} = [D.params[n].data[I1...] for n in I2]
getindex(D::NetworkData{T}, I1::Tuple{Int, Int},
    I2::Vector) where {T<:NetworkParams} =
    [D.params[n].data[I1...] for n in I2]
getindex(D::NetworkData{T}, I1::Tuple{Int, Int},
    I2::Vector{Bool}) where {T<:NetworkParams} = (length(D.params) == length(I2))?
    [D.params[n].data[I1...] for n in Base.LogicalIndex(I2)]:
    error("Length of the mask different from lenghth of the array attemped to access")
getindex(D::NetworkData{T}, I1::Tuple{Int, Int},
    I2::Colon) where {T<:NetworkParams} = getindex(D, I1, 1:length(D.params))
getindex(D::NetworkData{T}, I1::Tuple{Int, Int}) where {T<:NetworkParams} =
    getindex(D, I1, :)
# setindex!: TODO
#
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
>>>>>>> before discard
