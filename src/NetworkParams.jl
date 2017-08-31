export NetworkParams, Sparams, Yparams, Zparams
export TwoPortParams, ABCDparams

abstract type NetworkParams end
abstract type TwoPortParams <: NetworkParams end
import Base.show

"""
    Sparams(nPort, data) <: NetworkParams
Scattering parameters for microwave network
"""
mutable struct Sparams <: NetworkParams
    nPort::Int
    data::Array{Complex128, 2}
    function Sparams(nPort, data)
        nr, nc = size(data)
        if (nr != nPort) | (nc != nPort)
            error("Sparams Error: The number of ports doesn't match with either row or column of the data")
        end
        new(nPort, data)
    end
end
"""
Convenience constructor for `Sparams`
"""
Sparams(data) = Sparams(size(data)[1], data)

"""
    Yparams(nPort, data) <: NetworkParams
Admittance-parameters for microwave network
"""
mutable struct Yparams <: NetworkParams
    nPort::Int
    data::Array{Complex128, 2}
    function Yparams(nPort, data)
        nr, nc = size(data)
        if (nr != nPort) | (nc != nPort)
            error("Yparams Error: The number of ports doesn't match with either row or column of the data")
        end
        new(nPort, data)
    end
end
"""
    Convenience constructor for `Yparams`
"""
Yparams(data) = Yparams(size(data)[1], data)

"""
    Zparams(nPort, data) <: NetworkParams
Impedance-parameters for microwave network
"""
mutable struct Zparams <: NetworkParams
    nPort::Int
    data::Array{Complex128, 2}
    function Zparams(nPort, data)
        nr, nc = size(data)
        if (nr != nPort) | (nc != nPort)
            error("Zparams Error: The number of ports doesn't match with either row or column of the data")
        end
        new(nPort, data)
    end
end
"""
    Convenience constructor for `Zparams`
"""
Zparams(data) = Zparams(size(data)[1], data)

"""
    ABCDparams(nPort, data) <: NetworkParams
Transfer-parameters for microwave network
"""
mutable struct ABCDparams <: TwoPortParams
    nPort::Int
    data::Array{Complex128, 2}
    function ABCDparams(nPort, data)
        if nPort != 2
            error("ABCDparams Error: nPort must be equal to 2 for ABCDparams")
        end
        nr, nc = size(data)
        if (nr != nPort) | (nc != nPort)
            error("ABCDparams Error: The number of ports doesn't match with either row or column of the data")
        end
        new(nPort, data)
    end
end
"""
    Convenience constructor for `ABCDparams`
"""
ABCDparams(data) = ABCDparams(2, data)


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
