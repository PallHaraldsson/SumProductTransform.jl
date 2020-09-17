module SumDenseProduct
using Distributions, NNlib, Flux, Unitary, Zygote, StatsBase, FillArrays

include("scope.jl")

const COLORS = [:blue, :red, :green, :yellow, :cyan, :magenta]

function paddedprint(io, s...; color=:default, pad=[])
    for (c, p) in pad
        printstyled(io, p, color=c)
    end
    printstyled(io, s..., color=color)
end

"""
	A fallback method
"""
function dsprint(io, s ; pad = [])
	paddedprint(io, s, pad = pad)
end

function dsprint(io::IO, n::MvNormal; pad=[])
    c = COLORS[(length(pad)%length(COLORS))+1]
    paddedprint(io, " MvNormal\n", color=c)
end


function logsumexp(x; dims = :)
	xm = maximum(x, dims = dims)
	log.(sum(exp.(x .- xm), dims = dims)) .+ xm
end

logsoftmax(x; dims = :) = x .- logsumexp(x, dims = dims)
softmax(x; dims = :) = exp.(logsoftmax(x, dims = dims))

log_normal(x) = - sum(x.^2, dims=1) / 2 .- size(x,1)*log(Float32(2π)) / 2
log_normal(x,μ) = log_normal(x .- μ)
log_normal(x,μ, σ2::T) where {T<:Number} = - sum((@. ((x - μ)^2)/σ2), dims=1)/2 .- size(x,1)*log(σ2*2π)/2

#Let's do a little bit of function stealing
Distributions.logpdf(p::MvNormal, x::AbstractMatrix) = log_normal(x)[:]
Distributions.logpdf(p::MvNormal, x::AbstractMatrix, S::NoScope) = log_normal(x)[:]

batchlogpdf(p, x, bs::Int) = reduce(vcat, map(i -> logpdf(p, x[:,i]), Iterators.partition(1:size(x,2), bs)))


"""
    pathcount(m)

    Number of possible path of a model. For distributions it defaults to one.
"""
pathcount(m) = 1

"""
    treelogpdf(p, x, path)

    logpdf of samples `x` calculated along the `path` determining components in sumnodes (at the moment)
    For distributions outside the SumDenseProduct it falls back to logpdf(p, x).
"""
treelogpdf(m, x, path) = logpdf(m, x)
treelogpdf(m, x, path, s::AbstractScope) = logpdf(m, x)

_maptree(m, x, s::AbstractScope = NoScope())= (logpdf(m,x), fill(tuple(), size(x, 2)))

batchtreelogpdf(m, x, path) = map(i -> treelogpdf(m, x[:,i:i], path[i])[1], 1:length(path))


function Distributions.logpdf(m::M, x::AbstractMatrix) where {M<: MvNormal{T,Distributions.PDMats.ScalMat{T},FillArrays.Zeros{T,1,Tuple{Base.OneTo{Int64}}}}} where {T}
  log_normal(x, m.μ)[:]
end

_priors(m) = nothing
function priors!(ps, x, seen = Flux.IdSet())
  x in seen && return
  push!(seen, x)
  xx = _priors(x)
  !isnothing(xx) && push!(ps, xx)
  for child in Flux.trainable(x)
    priors!(ps, child, seen)
  end
end

function priors(m)
  ps = []
  priors!(ps, m)
  return ps
end

include("priors.jl")
include("scopedsvd.jl")
include("threadedgrads.jl")
include("sumnode.jl")
include("densenode.jl")
include("productnode.jl")
include("learnableproductnode.jl")
include("modelbuilders.jl")
include("fit.jl")
include("smartinit.jl")
include("fitting/em.jl")


"""
    path = samplepath(m)

    sample a path trough the model, which can be used by treelogpdf to calculate the
    pdf along this path.
"""
samplepath(m) = tuple()
samplepath(m, s::AbstractScope) = (s,)

export SumNode, DenseNode, ProductNode, LearnableProductNode
export densesharedmixture, nosharedmixture, allsharedmixture, priors, updatelatent!, buildmixture, pathcount, batchlogpdf
export em!, fit!

end # module
