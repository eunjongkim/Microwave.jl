module Microwave
# TouchstoneRead.jl
# Author: Eunjong Kim
import Base: +, -, *, ^, convert, show
export NetworkData, NetworkParams, Sparams, Yparams, Zparams, ABCDparams

abstract type NetworkParams end
abstract type Sparams <: NetworkParams end
abstract type Yparams <: NetworkParams end
abstract type Zparams <: NetworkParams end
abstract type ABCDparams <: NetworkParams end

"""
    NetworkData{T<:NetworkParams}
"""
mutable struct NetworkData{T<:NetworkParams}
    typ::Type{T}
    nPort::Int64
    nPoint::Int64
    impedance::Float64
    freq::Array{Float64, 1}
    data::Array{Complex128, 3}
    function NetworkData{T}(typ, nPort, nPoint, impedance, freq, data) where {T}
        n1, n2, n3 = size(data)
        if (n1 != nPort) | (n2 != nPort)
            error("NetworkData Error: the number of rows and columns doesn't match with `nPort`")
        end
        if n3 != nPoint
            error("NetworkData Error: the number of data points doesn't match with `nPoint`")
        end
        if (typ == ABCDparams) & (nPort !=2)
            error("NetworkData Error: ABCD-parameters are defined only for nPort=2 networks.")
        end
        new(typ, nPort, nPoint, impedance, freq, data)
    end
end

"""
    NetworkData{T<:NetworkParams}(typ::Type{T}, nPort, nPoint, impedance, freq, data)
Method for converting input arguments into appropriate types for a touchstone data
"""
NetworkData{T<:NetworkParams}(typ::Type{T}, nPort, nPoint, impedance, freq, data) =
    NetworkData{T}(typ, Int64(nPort), Int64(nPoint), Float64(impedance),
        Vector{Float64}(freq), Array{Complex128, 3}(data))

"""
    NetworkData(typ::Type{T}, freq, data, impedance=50.0)
Simple method for creating a `NetworkData` object.
"""
function NetworkData(typ::Type{T}, freq, data, impedance=50.0) where {T<:NetworkParams}
    n1, n2, n3 = size(data)
    return NetworkData(typ, n1, n3, impedance, freq, data)
end

function show(io::IO, x::NetworkData)
    if x.typ == Sparams
        parameter_type = "S"
    elseif x.typ == Yparams
        parameter_type = "Y"
    elseif x.typ == Zparams
        parameter_type = "Z"
    elseif x.typ == ABCDparams
        parameter_type = "ABCD"
    end
    write(io, "$(x.nPort)-port $(parameter_type)-parameters (impedance = $(x.impedance), # of datapoints = $(x.nPoint))")
end
include("Touchstone.jl")
include("convert.jl")
include("read.jl")
include("connect.jl")


end # module
