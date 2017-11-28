
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
    Port
`index`: global index of the port. A port index unique in the system is
assigned whenever an instance of `Port` is created.
`impedance`: impedance of the port.
"""
struct Port
    index::Int
    impedance::Impedance
    Port(impedance::Impedance{T}) where {T<:Number} =
        new(port_counter(), impedance)
end
Port(impedance::Number) = Port(Impedance(impedance))



# check_is_uniform(ports::Vector{Port{T}}) where {T<:Number} =

"""
    NetworkData{S<:Real, T<:NetworkParams}
"""
mutable struct NetworkData{S<:Real, T<:NetworkParams} <: AbstractData
    nPort::Int
    nPoint::Int
    is_uniform::Bool
    ports::Vector{Port}
    frequency::Vector{S}
    params::Vector{T}
    function NetworkData(ports::Vector{Port}, frequency::AbstractVector{S},
        params::Vector{T}) where {S<:Real, T<:NetworkParams}
        nPoint = length(frequency)
        nPort = length(ports)
        is_uniform = all(n -> (ports[1].impedance == ports[n].impedance), 1:nPort)
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
        new{S, T}(nPort, nPoint, is_uniform, ports, frequency, params)
    end
end

"""
    NetworkData(frequency, params; port_impedance=50.0)
Convenience constructor for creating a `NetworkData` object of uniform port
impedances.
"""
NetworkData(frequency::AbstractVector{S}, params::Vector{T};
    impedance=Impedance(50.0)) where {S<:Real, T<:NetworkParams} =
    NetworkData([Port(impedance) for n in 1:params[1].nPort], frequency, params)

"""
    show(io::IO, D::NetworkData{T}) where {T<:NetworkParams}
Pretty-printing of `NetworkData`.
"""
function show(io::IO, D::NetworkData{S, T}) where {S<:Real, T<:NetworkParams}
    write(io, "$(D.nPort)-port $(typeof(D)):\n")
    write(io, "  Number of datapoints = $(D.nPoint)\n")
    write(io, "  Port Informaton:\n")
    for (n, p) in enumerate(D.ports)
        write(io, "    Port $(n) → (index = $(p.index), impedance = $(p.impedance))\n")
    end
end

impedances(ports::Vector{Port}) = [p.impedance.data for p in ports]
impedances(D::NetworkData) = impedances(D.ports)

"""
`getindex` methods for `NetworkData{T<:NetworkParams}`. The first input argument
in the square bracket must be a 2-integer tuple (i, j) denoting which element of
parameter to get. The second input argument is either a scalar integer, Range,
integer vector, mask, or colon(:) that determines which datapoint to choose.
i.e., `D[(i, j), n]` returns the n-th data of parameter Tᵢⱼ
where T∈{S,Y,Z,ABCD,...}.
"""
getindex(D::NetworkData{S, T}, I1::Tuple{Int, Int},
    I2::Int) where {S<:Real, T<:NetworkParams} = D.params[I2].data[I1...]
getindex(D::NetworkData{S, T}, I1::Tuple{Int, Int},
    I2::Range) where {S<:Real, T<:NetworkParams} = [D.params[n].data[I1...] for n in I2]
getindex(D::NetworkData{S, T}, I1::Tuple{Int, Int},
    I2::Vector) where {S<:Real, T<:NetworkParams} =
    [D.params[n].data[I1...] for n in I2]
getindex(D::NetworkData{S, T}, I1::Tuple{Int, Int},
    I2::Vector{Bool}) where {S<:Real, T<:NetworkParams} =
    (length(D.params) == length(I2))?
    [D.params[n].data[I1...] for n in Base.LogicalIndex(I2)]:
    error("Length of the mask different from lenghth of the array attemped to access")
getindex(D::NetworkData{S, T}, I1::Tuple{Int, Int},
    I2::Colon) where {S<:Real, T<:NetworkParams} = getindex(D, I1, 1:length(D.params))
getindex(D::NetworkData{S, T}, I1::Tuple{Int, Int}) where {S<:Real, T<:NetworkParams} =
    getindex(D, I1, :)
# setindex!: TODO
#
