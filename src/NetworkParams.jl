export NetworkParams, Sparams, Yparams, Zparams
export TwoPortParams, ABCDparams

abstract type NetworkParams end
abstract type TwoPortParams <: NetworkParams end


"""
    Sparams(nPort, data) <: NetworkParams
Scattering parameters for microwave network. Contains a
"""
mutable struct Sparams <: NetworkParams
    nPort::Int
    data::Array{Complex{BigFloat}, 2}
    function Sparams(data)
        nr, nc = size(data)
        if nr != nc
            error("Sparams Error: The number of rows and columns doesn't match")
        else
            new(nr, data)
        end
    end
end

"""
    Yparams(nPort, data) <: NetworkParams
Admittance-parameters for microwave network
"""
mutable struct Yparams <: NetworkParams
    nPort::Int
    data::Array{Complex{BigFloat}, 2}
    function Yparams(data)
        nr, nc = size(data)
        if nr != nc
            error("Yparams Error: The number of rows and columns doesn't match")
        else
            new(nr, data)
        end
    end
end

"""
    Zparams(nPort, data) <: NetworkParams
Impedance-parameters for microwave network
"""
mutable struct Zparams <: NetworkParams
    nPort::Int
    data::Array{Complex{BigFloat}, 2}
    function Zparams(data)
        nr, nc = size(data)
        if nr != nc
            error("Zparams Error: The number of rows and columns doesn't match")
        else
            new(nr, data)
        end
    end
end

"""
    ABCDparams(nPort, data) <: NetworkParams
Transfer-parameters for microwave network
"""
mutable struct ABCDparams <: TwoPortParams
    nPort::Int
    data::Array{Complex{BigFloat}, 2}
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
