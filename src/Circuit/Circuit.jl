module Circuit

import Microwave: AbstractParams, AbstractData
import Base: +, -, *, /, ^, ==, convert, promote_rule, show, getindex

export CircuitParams, Impedance, Admittance, CircuitData, ∥
export capacitor, inductor, resistor

include("CircuitParams.jl")
include("CircuitData.jl")
include("convert.jl")
include("operations.jl")
include("RLC.jl")

end
