# This file is a part of Julia. License is MIT: http://julialang.org/license

"""
    NullException()

An attempted access to a [`Nullable`](:obj:`Nullable`) with no defined value.
"""
immutable NullException <: Exception
end

"""
    Nullable(x, isnull::Bool=false)

Wrap value `x` in an object of type `Nullable`, which indicates whether a value is present.
`Nullable(x)` yields a non-empty wrapper, and `Nullable{T}()` yields an empty instance of a
wrapper that might contain a value of type `T`.

```jldoctest
julia> Nullable()
Nullable{Union{}}()

julia> Nullable(2)
Nullable{Int64}(2)

julia> Nullable(0, true)
Nullable{Int64}()

julia> Nullable(0, false)
Nullable{Int64}(0)
```
"""
Nullable{T}(value::T, isnull::Bool=false) = Nullable{T}(value, isnull)
Nullable() = Nullable{Union{}}()

eltype{T}(::Type{Nullable{T}}) = T

convert{T}(::Type{Nullable{T}}, x::Nullable{T}) = x
convert(   ::Type{Nullable   }, x::Nullable   ) = x

convert{T}(t::Type{Nullable{T}}, x::Any) = convert(t, convert(T, x))

function convert{T}(::Type{Nullable{T}}, x::Nullable)
    return isnull(x) ? Nullable{T}() : Nullable{T}(convert(T, get(x)))
end

convert{T}(::Type{Nullable{T}}, x::T) = Nullable{T}(x)
convert{T}(::Type{Nullable   }, x::T) = Nullable{T}(x)

convert{T}(::Type{Nullable{T}}, ::Void) = Nullable{T}()
convert(   ::Type{Nullable   }, ::Void) = Nullable{Union{}}()

promote_rule{S,T}(::Type{Nullable{S}}, ::Type{T}) = Nullable{promote_type(S, T)}
promote_rule{S,T}(::Type{Nullable{S}}, ::Type{Nullable{T}}) = Nullable{promote_type(S, T)}
promote_op{S,T}(op::Any, ::Type{Nullable{S}}, ::Type{Nullable{T}}) = Nullable{promote_op(op, S, T)}

function show{T}(io::IO, x::Nullable{T})
    if get(io, :compact, false)
        if isnull(x)
            print(io, "#NULL")
        else
            show(io, x.value)
        end
    else
        print(io, "Nullable{")
        showcompact(io, eltype(x))
        print(io, "}(")
        if !isnull(x)
            showcompact(io, x.value)
        end
        print(io, ')')
    end
end

"""
    get(x::Nullable[, y])

Attempt to access the value of `x`. Returns the value if it is present;
otherwise, returns `y` if provided, or throws a `NullException` if not.
"""
@inline function get{S,T}(x::Nullable{S}, y::T)
    if isbits(S)
        ifelse(x.isnull, y, x.value)
    else
        x.isnull ? y : x.value
    end
end

get(x::Nullable) = x.isnull ? throw(NullException()) : x.value


"""
    isnull(x::Nullable) -> Bool

Is the [`Nullable`](:obj:`Nullable`) object `x` null, i.e. missing a value?

```jldoctest
julia> x = Nullable(1, false)
Nullable{Int64}(1)

julia> isnull(x)
false

julia> x = Nullable(1, true)
Nullable{Int64}()

julia> isnull(x)
true
```
"""
isnull(x::Nullable) = x.isnull

function isequal(x::Nullable, y::Nullable)
    if x.isnull && y.isnull
        return true
    elseif x.isnull || y.isnull
        return false
    else
        return isequal(x.value, y.value)
    end
end

==(x::Nullable, y::Nullable) = throw(NullException())

const nullablehash_seed = UInt === UInt64 ? 0x932e0143e51d0171 : 0xe51d0171

function hash(x::Nullable, h::UInt)
    if x.isnull
        return h + nullablehash_seed
    else
        return hash(x.value, h + nullablehash_seed)
    end
end
