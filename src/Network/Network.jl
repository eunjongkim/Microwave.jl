module Network

import Microwave: AbstractParams, AbstractData
import Base: +, -, *, /, ^, convert, promote_rule, show

export NetworkParams, Sparams, Yparams, Zparams
export TwoPortParams, ABCDparams

abstract type NetworkParams{T<:Number} <: AbstractParams end
abstract type TwoPortParams{T<:Number} <: NetworkParams{T} end

check_row_column(data::Array{T, 2}) where {T<:NetworkParams} =
    begin nr, nc = size(data)
        (nr == nc)? nr: error("Number of rows and columns doesn't match")
    end

"""
    Sparams(nPort, data) <: NetworkParams
Scattering parameters for microwave network. Contains a
"""
mutable struct Sparams{T<:Number} <: NetworkParams{T}
    nPort::Int
    data::Array{T, 2}
    Sparams(data::Array{T, 2}) where {T<:Number} =
        new{T}(check_row_column(data), data)
end

"""
    Yparams(nPort, data) <: NetworkParams
Admittance-parameters for microwave network
"""
mutable struct Yparams{T<:Number} <: NetworkParams{T}
    nPort::Int
    data::Array{T, 2}
    Yparams(data::Array{T, 2}) where {T<:Number} =
        new{T}(check_row_column(data), data)
end

"""
    Zparams(nPort, data) <: NetworkParams
Impedance-parameters for microwave network
"""
mutable struct Zparams{T<:Number} <: NetworkParams{T}
    nPort::Int
    data::Array{T, 2}
    Zparams(data::Array{T, 2}) where {T<:Number} =
        new{T}(check_row_column(data), data)
end

"""
    ABCDparams(nPort, data) <: NetworkParams
Transfer-parameters for microwave network
"""
mutable struct ABCDparams{T<:Number} <: TwoPortParams{T}
    nPort::Int
    data::Array{Complex{MFloat}, 2}
    function ABCDparams(data)
        nr, nc = size(data)
        if nr != nc
            error("ABCDparams Error: The number of rows and columns doesn't match")
        else
            if (nr!=2)|(nc!=2)
                error("ABCDparams Error: the number of ports must be equal to 2")
            else
                new(nr, data)
            end
        end
    end
end

"""
    show(io::IO, params::NetworkParams)
Pretty-printing of `NetworkParams`
"""
function show(io::IO, params::NetworkParams)
    write(io, "$(params.nPort)-port $(typeof(params))\n")
    for nr in 1:(params.nPort)
        for nc in 1:(params.nPort)
            write(io, "$((params.data)[nr, nc])\t")
        end
        write(io, "\n")
    end
end

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
