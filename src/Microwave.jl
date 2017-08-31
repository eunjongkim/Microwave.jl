module Microwave
# Microwave.jl
# Author: Eunjong Kim
import Base: +, -, *, ^, convert, show, getindex, setindex!

# Definitions of NetworkParams, NetworkData
include("NetworkParams.jl")
include("NetworkData.jl")
# Touchstone (*.sNp) format
# include("Touchstone.jl")
# # Conversion between different NetworkParams
# include("convert.jl")
# # Connection between NetworkData
# include("connect.jl")

end # module
