abstract type LumpedElementParams end
abstract type Impedance <: LumpedElementParams end
abstract type Admittance <: LumpedElementParams end

"""
A lumped-element object specified by its impedance
"""
mutable struct LumpedElement{T<:LumpedElementParams}
    typ::Type{T}
    func::Function
end
LumpedElement(typ::Type{T}, func::Function) where {T<:LumpedElementParams} =
    LumpedElement{T}(typ, func)

convert(::Type{T}, L::LumpedElement) where {T<:LumpedElementParams} =
    convert(::Type{LumpedElement{T}}, L)
convert(::Type{LumpedElement{Impedance}}, L::LumpedElement{Admittance}) =
    LumpedElement(Impedance, ω -> 1/L.func(ω))
convert(::Type{LumpedElement{Admittance}}, L::LumpedElement{Impedance}) =
    LumpedElement(Impedance, ω -> 1/L.func(ω))

import Base: +

# series
+(L1::LumpedElement, L2::LumpedElement) =
    LumpedElement(ω->(L1.impedance(ω) + L2.impedance(ω)))
# parallel
∥(L1::LumpedElement, L2::LumpedElement) =
    LumpedElement(ω->1/(1/L1.impedance(ω) + 1/L2.impedance(ω)))

capacitor(C) = LumpedElement(Impedance, ω -> 1/(im * ω * C))
inductor(L) = LumpedElement(Impedance, ω -> (im * ω * L))
resistor(R) = LumpedElement(Impedance, ω -> R)


abstract type AbstractNetwork end

"""
    TNetwork
     ┌────┐       ┌────┐
○────┤ L1 ├───┬───┤ L2 ├───○
     └────┘ ┌─┴─┐ └────┘
port1       |L3 |      port2
            └─┬─┘
○─────────────┴────────────○

"""
mutable struct TNetwork <: AbstractNetwork
    L1::LumpedElement
    L2::LumpedElement
    L3::LumpedElement
end
