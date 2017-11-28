abstract type NetworkParams{T<:Number} <: AbstractParams end
abstract type TwoPortParams{T<:Number} <: NetworkParams{T} end

check_row_column(data::Array{T, 2}) where {T<:Number} =
    begin nr, nc = size(data)
        (nr == nc)? nr: error("Number of rows and columns doesn't match")
    end

"""
    Sparams(nPort, data) <: NetworkParams
Scattering parameters for microwave network.
"""
mutable struct Sparams{T<:Number} <: NetworkParams{T}
    nPort::Int
    data::Array{T, 2}
    Sparams(data::Array{T, 2}) where {T<:Number} =
        new{T}(check_row_column(data), data)
end
Sparams(P::Vector{Array{T, 2}}) where {T<:Number} = [Sparams(p) for p in P]

"""
    Yparams(nPort, data) <: NetworkParams
Admittance parameters for microwave network
"""
mutable struct Yparams{T<:Number} <: NetworkParams{T}
    nPort::Int
    data::Array{T, 2}
    Yparams(data::Array{T, 2}) where {T<:Number} =
        new{T}(check_row_column(data), data)
end
Yparams(P::Vector{Array{T, 2}}) where {T<:Number} = [Yparams(p) for p in P]

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
Zparams(P::Vector{Array{T, 2}}) where {T<:Number} = [Zparams(p) for p in P]

"""
    ABCDparams(nPort, data) <: NetworkParams
Transfer-parameters for microwave network
"""
mutable struct ABCDparams{T<:Number} <: TwoPortParams{T}
    nPort::Int
    data::Array{T, 2}
    ABCDparams(data::Array{T, 2}) where {T<:Number} = begin
        n = check_row_column(data)
        (n == 2)? new{T}(n, data): error("ABCDparams are defined only for 2×2 matrices")
    end
end
ABCDparams(P::Vector{Array{T, 2}}) where {T<:Number} = [ABCDparams(p) for p in P]

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
