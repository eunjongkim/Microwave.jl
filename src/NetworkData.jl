export Port, NetworkData, impedances, swapPorts!

let
    state = 0
    global p_counter
    """
        p_counter()
    Global counter for unique port indices (has to be unique for each port)
    """
    p_counter() = state += 1
end

"""
    Port(impedance::Float64)
`indPort`: global index of the port. A port index unique in the system is
assigned whenever an instance of `Port` is created.
`impedance`: impedance of the port.
"""
struct Port
    indPort::Int
    impedance::Complex128
    Port(impedance) = new(p_counter(), impedance)
end

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
NetworkData(frequency, params; impedance=50.0) =
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

impedances(ports::Array{Port, 1}) = [p.impedance for p in ports]
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

function swapPorts!(D::NetworkData{T}, i1::Int, i2::Int) where {T<:NetworkParams}
    D.ports[i1], D.ports[i2] = D.ports[i2], D.ports[i1]
    for n in 1:D.nPoint
        # swap rows
        D.params[n].data[i1, :], D.params[n].data[i2, :] =
            D.params[n].data[i2, :], D.params[n].data[i1, :]
        # swap columns
        D.params[n].data[:, i1], D.params[n].data[:, i2] =
            D.params[n].data[:, i2], D.params[n].data[:, i1]
    end
    return D
end

swapPorts(D::NetworkData{T}, i1::Int, i2::Int) where {T<:NetworkParams} =
    swapPorts!(deepcopy(_D), i1, i2)
