module Microwave
# Microwave.jl
# Author: Eunjong Kim
import Base: +, -, *, ^, /, convert, show, getindex, setindex!

#using Touchstone
include("Circuit\Circuit.jl")
include("Circuit\convert.jl")

# Definitions of NetworkParams, NetworkData
include("Network\NetworkParams.jl")
include("Network\NetworkData.jl")
include("Network\convert.jl")
include("Network\connect.jl")
include("Network\twoport.jl")


include("Touchstone\Touchstone.jl")
include("Touchstone\convert.jl")

# interpolate data
include("interpolate.jl")

end # module
