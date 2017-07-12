# Stable Set
# ==========

type StableSet{T} <: Base.AbstractSet{T}
    dict::StableDict{T,Void}

    function (::Type{StableSet{T}}){T}()
        return new{T}(StableDict{T,Void}())
    end
end

function StableSet(vals)
    set = StableSet{eltype(vals)}()
    for v in vals
        push!(set, v)
    end
    return set
end

function Base.copy(set::StableSet)
    newset = StableSet{eltype(set)}()
    newset.dict = copy(set.dict)
    return newset
end

function Base.length(set::StableSet)
    return length(set.dict)
end

function Base.eltype{T}(::Type{StableSet{T}})
    return T
end

function Base.:(==)(set1::StableSet, set2::StableSet)
    if length(set1) == length(set2)
        for x in set1
            if x ∉ set2
                return false
            end
        end
        return true
    end
    return false
end

function Base.hash(set::StableSet, h::UInt)
    h = hash(Base.hashs_seed, h)
    for x in set
        h = xor(h, hash(x))
    end
    return h
end

function Base.in(set::StableSet, val)
    return haskey(set.dict, val)
end

function Base.push!(set::StableSet, val)
    v = convert(eltype(set), val)
    if v ∉ set
        set.dict[v] = nothing
    end
    return set
end

function Base.pop!(set::StableSet)
    return pop!(set.dict)[1]
end

function Base.delete!(set::StableSet, val)
    delete!(set.dict, val)
    return set
end

function Base.union!(set::StableSet, xs)
    for x in xs
        push!(set, x)
    end
    return set
end

function Base.union(set::StableSet, xs)
    return union!(copy(set), xs)
end

function Base.filter(f::Function, set::StableSet)
    newset = Set{eltype(set)}()
    for x in set
        if f(x)
            push!(newset, x)
        end
    end
    return newset
end

function Base.start(set::StableSet)
    return start(set.dict)
end

function Base.done(set::StableSet, s)
    return done(set.dict, s)
end

function Base.next(set::StableSet, s)
    item, s = next(set.dict, s)
    return item[1], s
end