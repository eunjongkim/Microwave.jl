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


function *(M1::TouchstoneData{ABCDparams}, M2::TouchstoneData{ABCDparams})
    if (M1.freq == M2.freq) & (M1.Z₀ == M2.Z₀)
        (_, _, n_col) = size(M1.data)
        M = zeros(Complex128, (2, 2, n_col))
        for n in 1:n_col
            M[:, :, n] = M1.data[:, :, n] * M2.data[:, :, n]
        end
        return TouchstoneData(ABCDparams, 2, M1.nPoint, M1.Z₀, M1.freq, M)
    else
        return error("Operations between data of different
            frequencies or characteristic impedances not supported")
    end
end

function ^(ABCD::TouchstoneData{ABCDparams}, N::Int)
    ABCDᴺ_data = zeros(Complex128, (2, 2, ABCD.nPoint))
    for n in 1:nPoint
        ABCDᴺ_data[:, :, n] = ABCD.data[:, :, n] ^ N
    end
    return TouchstoneData(ABCDparams, 2, ABCD.nPoint, ABCD.Z₀, ABCD.freq, ABCDᴺ_data)
end

"""
Read information (frequency unit, data type, format type, Z₀)
and data from a touchstone (.sNp) file.
"""
function read_touchstone(filepath::AbstractString; raw=false)
    f = open(filepath, "r")
    println("Reading touchstone file ", filepath, " ...")

    if ~(uppercase(filepath[end-2]) == 'S') | ~(uppercase(filepath[end]) == 'P')
        return error("Not a touchstone (.sNp) file.")
    else
        nPort = parse(Int, filepath[end-1])
    end

    phrase = "!"
    while phrase[1] != '#'
        #=
        read lines until first encountering '#', where frequency unit,
        data type, format type, and Z₀ are stored.
        =#
        phrase = readline(f)
    end

    _, freq_unit, data_type, format_type, _, Z₀ = split(phrase, " ");

    Z₀ = parse(Float64, Z₀)
    data = []
    while true
        line = readline(f)
        if line != ""
            while line[1] == '!'
                #=
                read lines until we encounter '!',
                where the touchstone file ends
                =#
                line = readline(f)
                if line == ""
                    break
                end
            end
            if line != ""
                data_vec = [parse(Float64, d) for d in split(line)]
            end
            data = [data..., data_vec]
        else
            break
        end
    end
    data = hcat([v for v in data]...)
    nPoint = length(data[1, :])
    close(f)
    touchstone = RawTouchstone(nPort, nPoint, Z₀, uppercase(freq_unit),
        uppercase(data_type), uppercase(format_type), data)
    if raw == true
        return touchstone
    else
        if data_type == "S"
            return convert(Sparams, touchstone)
        end
    end
end


"""
Cascade a 2-port touchstone data `Data::TouchstoneData{T}` `N::Int` times
"""
cascade{T<:TouchstoneParams}(Data::TouchstoneData{T}, N::Int) =
    convert(T, convert(ABCDparams, Data) ^ N)

"""
Terminate port 2 of a two-port network `s::TouchstoneData{Sparams}`
with a one-port touchstone data `t::TouchstoneData{Sparams, 1}`

s₁₁′ = s₁₁ + s₂₁t₁₁s₁₂ / (1 - t₁₁s₂₂)
"""
function terminate(s::TouchstoneData{Sparams}, t::TouchstoneData{Sparams})
    if (s.nPort != 2) | (t.nPort != 1)
        error("")
    end
    if (s.freq != t.freq) | (s.Z₀ != t.Z₀)
        return error("Operations between data of different
            frequencies or characteristic impedances not supported")
    end

    s′_data = zeros(Complex128, size(t.data))
    s′_data[1, 1, :] = (s.data[1, 1, :] + s.data[2, 1, :] .* t.data[1, 1, :]
        .* s.data[1, 2, :] ./ (1 - t.data[1, 1, :] .* s.data[2, 2, :]))
    return TouchstoneData{Sparams}(s.Z₀, s.freq, s′_data)
end
terminate{T<:TouchstoneParams, S<:TouchstoneParams}(s::TouchstoneData{T},
    t::TouchstoneData{S}) = terminate(convert(Sparams, s), convert(Sparams, t))

end # module
