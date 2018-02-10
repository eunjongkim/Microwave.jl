module Touchstone
using ..Network
export TouchstoneData, read_touchstone
"""
Touchstone data in its raw form, imported from a touchstone file `*.sNp`
"""
struct TouchstoneData
    nPort::Int
    nPoint::Int
    impedance::Float64
    freq_unit::String
    data_type::String
    format_type::String
    data::Array
end

function show(io::IO, x::TouchstoneData)
    write(io, "$(x.nPort)-Port $(x.nPoint) Point Touchstone with impedance = $(x.impedance), Freq Unit: $(x.freq_unit), Data Type: $(x.data_type), Format Type: $(x.format_type)")
end

include("convert.jl")

"""
Read information (frequency unit, data type, format type, impedance)
and data from a touchstone (.sNp) file.
"""
function read_touchstone(filepath::AbstractString;
    raw=false, floattype::Type{T}=Float64) where {T<:AbstractFloat}
    f = open(filepath, "r")
    info("Reading touchstone file ", filepath, " ...")

    if ~(uppercase(filepath[end-2]) == 'S') | ~(uppercase(filepath[end]) == 'P')
        return error("Not a touchstone (.sNp) file.")
    else
        nPort = parse(Int, filepath[end-1])
    end

    phrase = "!"
    while (length(phrase) == 0) || (phrase[1] != '#')
        #=
        read lines until first encountering '#', where frequency unit,
        data type, format type, and impedance are stored.
        =#
        phrase = readline(f)
    end

    _, freq_unit, data_type, format_type, _, impedance = split(phrase, " ");

    impedance = parse(Float64, impedance)
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
                data_vec = [parse(floattype, d) for d in split(line)]
            end
            data = [data..., data_vec]
        else
            break
        end
    end
    data = hcat([v for v in data]...)
    nPoint = length(data[1, :])
    close(f)
    touchstone = TouchstoneData(nPort, nPoint, impedance, uppercase(freq_unit),
    uppercase(data_type), uppercase(format_type), data)
    if raw == true
        return touchstone
    else
        if data_type == "S"
            return convert(Sparams, touchstone)
        end
    end
end

end
