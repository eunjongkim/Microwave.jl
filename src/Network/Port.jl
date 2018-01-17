
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
    Z0::Impedance
    Port(Z0::Impedance{T}) where {T<:Real} =
        new(port_counter(), Z0)
end
```
`index`: global index of the port. A port index unique in the system is
assigned whenever an instance of `Port` is created.
`Z0`: reference impedance of the port.
"""
struct Port
    index::Integer
    Z0::Impedance
    Port(Z0::Impedance{T}) where {T<:Real} =
        new(port_counter(), Z0)
end
Port(Z0::Number) = Port(Impedance(Z0))

function show(io::IO, port::Port)
    write(io, "Port $(port.index): Z0 = $(port.Z0.data)\n")
end

"""
    impedances
"""
impedances(ports::Vector{Port}) = [p.Z0.data for p in ports]
is_uniform(ports::Vector{Port}) = foldl(==, impedances(ports))
