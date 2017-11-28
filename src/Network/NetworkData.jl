export Port, NetworkData, impedances, swap_ports!, permute_ports!

let
    state = 0
    global port_counter
    """
        port_counter()
    Global counter for unique port indices (has to be unique for each port)
    """
    port_counter() = state += 1
end

"""
    Port{T<:Number}
`index`: global index of the port. A port index unique in the system is
assigned whenever an instance of `Port` is created.
`impedance`: impedance of the port.
"""
struct Port{T<:Number}
    index::Int
    impedance::Impedance{T}
    Port(impedance) = new(port_counter(), impedance)
end

# check_is_uniform(ports::Vector{Port{T}}) where {T<:Number} =

"""
    NetworkData{T<:NetworkParams}
"""
mutable struct NetworkData{S<:Real, T<:NetworkParams} <: NetworkData
    nPort::Int
    nPoint::Int
    is_uniform::Bool
    ports::Vector{Port{N}} where {N<:Number}
    frequency::Vector{S}
    params::Vector{T}
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
        write(io, "\t\tPort $(n) → (global index = $(p.index), Z₀ = $(p.impedance))\n")
    end
end

impedances(ports::Vector{Port{T}}) where {T<:Number} = [p.impedance for p in ports]
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
