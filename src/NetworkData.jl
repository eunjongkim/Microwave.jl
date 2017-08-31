import Base: getindex, setindex!

"""
    NetworkData{T<:NetworkParams}
"""
mutable struct NetworkData{T<:NetworkParams}
    nPort::Int
    nPoint::Int
    port_impedance::Float64
    frequency::Array{Float64, 1}
    params::Array{T, 1}
    function NetworkData(nPort, nPoint, port_impedance, frequency,
        params::Array{T,1}) where {T<:NetworkParams}
        if (length(params) != nPoint) | (length(frequency) != nPoint)
            error("NetworkData Error: the number of data points doesn't match with `nPoint`")
        end
        if ~all(n -> (nPort == params[n].nPort), 1:nPoint)
            error("NetworkData Error: the number of ports in params doesn't match with `nPort`")
        end
        # if (typeof(port_impedance) == Array{Float64, 1}) & (length(port_impedance) != nPort)
        #     error("The number of port impedances does not  match with `nPort`")
        # end
        new{T}(nPort, nPoint, port_impedance, frequency, params)
    end
end

"""
    NetworkData(frequency, params, port_impedance=50.0)
Convenience constructor for creating a `NetworkData` object.
"""
function NetworkData(frequency, params, port_impedance=50.0)
    nPoint = length(params)
    nPort = params[1].nPort
    return NetworkData(nPort, nPoint, port_impedance, frequency, params)
end

"""
    show(io::IO, D::NetworkData{T}) where {T<:NetworkParams}
"""
function show(io::IO, D::NetworkData{T}) where {T<:NetworkParams}
    write(io, "$(D.nPort)-port $(typeof(D)):\n")
    write(io, "\tPort impedance = $(D.port_impedance),\n")
    write(io, "\tNumber of datapoints = $(D.nPoint)")
end

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
    I2::Vector{Bool}) where {T<:NetworkParams} = (D.nPoint == length(I2))?
    [D.params[n].data[I1...] for n in Base.LogicalIndex(I2)]:
    error("Length of the mask different from lenghth of the array attemped to access")
getindex(D::NetworkData{T}, I1::Tuple{Int, Int},
    I2::Colon) where {T<:NetworkParams} = getindex(D, I1, 1:D.nPoint)

# setindex!?
