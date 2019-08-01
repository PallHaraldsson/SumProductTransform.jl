struct DenseP{M,MI,P} <: Distributions.ContinuousMultivariateDistribution
	m::M
	mi::MI
	p::P 
end

Flux.@treelike(DenseP)

DenseP(m, p) = DenseP(m, inv(m), p)

function Distributions.logpdf(m::DenseP, x::AbstractMatrix)
	x, l = m.m((x,0))
	logpdf(m.p, x) .+ l[:]
end

function Distributions.logpdf(m::M, x::AbstractMatrix) where {M<: MvNormal{T,Distributions.PDMats.ScalMat{T},Distributions.ZeroVector{T}}} where {T}
	log_normal(x, m.μ)[:]
end