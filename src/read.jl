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
