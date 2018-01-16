
let
    state = 0
    global port_counter
    """
        port_counter()
    Global counter for unique port indices (has to be unique for each port)
    """
    port_counter() = state += 1
end

"""
```
struct Port
    index::Integer
    impedance::Impedance
    Port(impedance::Impedance{T}) where {T<:Number} =
        new(port_counter(), impedance)
end
```
`index`: global index of the port. A port index unique in the system is
assigned whenever an instance of `Port` is created.
`impedance`: impedance of the port.
"""
struct Port
    index::Integer
    impedance::Impedance
    Port(impedance::Impedance{T}) where {T<:Real} =
        new(port_counter(), impedance)
end
Port(impedance::Number) = Port(Impedance(impedance))

function show(io::IO, port::Port)
    write(io, "Port $(port.index): impedance = $(port.impedance.data)\n")
end


is_uniform(ports::Vector{Port}) =
    all(n -> (ports[1].impedance == ports[n].impedance), 1:nPort)
