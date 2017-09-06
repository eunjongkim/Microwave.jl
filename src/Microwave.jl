module Microwave
# Microwave.jl
# Author: Eunjong Kim
import Base: +, -, *, ^, convert, show, getindex, setindex!

using Touchstone
# Definitions of NetworkParams, NetworkData
include("NetworkParams.jl")
include("NetworkData.jl")

reflection_coefficient(Z1, Z2) = (Z2 - Z1) / (Z2 + Z1)
transmission_coefficient(Z1, Z2) = 1 + reflection_coefficient(Z1, Z2)
impedance_step(Z1, Z2) =
    Sparams([reflection_coefficient(Z1, Z2) transmission_coefficient(Z2, Z1);
        transmission_coefficient(Z1, Z2) reflection_coefficient(Z2, Z1)])

check_two_port(ntwk::NetworkData{T}) where {T<:NetworkParams} =
    (ntwk.nPort == 2)
check_is_uniform(ntwk::NetworkData{T}) where {T<:NetworkParams} =
    (ntwk.is_uniform == true)
# Touchstone (*.sNp) format
# include("Touchstone.jl")
# Conversion between different NetworkParams
include("convert.jl")
# # Connection between NetworkData
include("connect.jl")

end # module
