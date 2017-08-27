module Touchstone
# TouchstoneRead.jl
# Author: Eunjong Kim
import Base: +, -, *, ^, convert, show
export TouchstoneParams, Sparams, Yparams, Zparams, ABCDparams
export TouchstoneData, RawTouchstone
export read_touchstone, cascade, terminate

abstract type TouchstoneParams end
abstract type Sparams <: TouchstoneParams end
abstract type Yparams <: TouchstoneParams end
abstract type Zparams <: TouchstoneParams end
abstract type ABCDparams <: TouchstoneParams end

"""
Touchstone data in its raw form, imported from a touchstone file `*.sNp`
"""
mutable struct RawTouchstone
    nPort::Int
    nPoint::Int
    Z₀::Float64
    freq_unit::String
    data_type::String
    format_type::String
    data::Array
end

function show(io::IO, x::RawTouchstone)
    write(io, "$(x.nPort)-Port $(x.nPoint) Points RawTouchstone with Z₀ = $(x.Z₀), Freq Unit: $(x.freq_unit), Data Type: $(x.data_type), Format Type: $(x.format_type)")
end


"""
    TouchstoneData{T<:TouchstoneParams}

"""
mutable struct TouchstoneData{T<:TouchstoneParams}
    typ::Type{T}
    nPort::Int
    nPoint::Int
    Z₀::Float64
    freq::Array{Float64, 1}
    data::Array{Complex128, 3}
    function TouchstoneData{T}(typ, nPort, nPoint, Z₀, freq, data) where {T}
        n1, n2, n3 = size(data)
        if (n1 != nPort) | (n2 != nPort)
            error("Touchstone Error: the number of rows and columns doesn't match with `nPort`")
        end
        if n3 != nPoint
            error("Touchstone Error: the number of data points doesn't match with `nPoint`")
        end
        if (typ == ABCDparams) & (nPort !=2)
            error("Touchstone Error: ABCD-parameters are defined only for nPort=2 networks.")
        end
        new(typ, nPort, nPoint, Z₀, freq, data)
    end
end
"""
    TouchstoneData{T<:TouchstoneParams}(typ::Type{T}, nPort, nPoint, Z₀, freq, data)
Method for converting input arguments into appropriate types for a touchstone data
"""
TouchstoneData{T<:TouchstoneParams}(typ::Type{T}, nPort, nPoint, Z₀, freq, data) =
    TouchstoneData{T}(typ, Int(nPort), Int(nPoint), Float64(Z₀),
        Vector{Float64}(freq), Array{Complex128, 3}(data))

"""
    TouchstoneData(typ::Type{T}, freq, data, Z₀=50.0)
Method for creating a `TouchstoneData` object.
"""
function TouchstoneData(typ::Type{T}, freq, data, Z₀=50.0) where {T<:TouchstoneParams}
    n1, n2, n3 = size(data)
    return TouchstoneData(typ, n1, n3, Z₀, freq, data)
end

function show(io::IO, x::TouchstoneData)
    if x.typ == Sparams
        parameter_type = "S"
    elseif x.typ == Yparams
        parameter_type = "Y"
    elseif x.typ == Zparams
        parameter_type = "Z"
    elseif x.typ == ABCDparams
        parameter_type = "ABCD"
    end
    write(io, "$(x.nPort)-port $(parameter_type)-parameters (Z₀ = $(x.Z₀), # of datapoints = $(x.nPoint))")
end

include("convert.jl")
include("read.jl")
include("connect.jl")


end # module
