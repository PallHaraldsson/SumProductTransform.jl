using ToyProblems, Distributions, SumDenseProduct, Unitary, Flux, Setfield
using Flux:throttle
using SumDenseProduct: fit!, mappath, samplepath
using ToyProblems: flower2
using Unitary: ScaleShift, SVDDense

using Plots
plotly()

function plot_contour(m, x, title = nothing)
	levels = quantile(exp.(logpdf(m, x)), 0.01:0.09:0.99)
	δ = levels[1] / 10
	levels = vcat(collect(levels[1] - 10δ:δ:levels[1] - δ), levels)
	xr = range(minimum(x[1,:]) - 1 , maximum(x[1,:])+ 1 , length = 200)
	yr = range(minimum(x[2,:]) - 1 , maximum(x[2,:])+ 1 , length = 200)
	p1 = contour(xr, yr, (x...) ->  exp(logpdf(m, [x[1],x[2]])[1]))
	p2 = deepcopy(p1)
	xx = x[:,sample(1:size(x,2), 100, replace = false)]
	scatter!(p2, x[1,:], x[2,:], alpha = 0.4)
	p = plot(p1, p2)
	!isnothing(title) && title!(p, title)
	p
end

function plot_components(m, x)
	path = hash.(mappath(m, x)[2])
	u = unique(path)
	hash2int = Dict(u[i] => i for i in 1:length(u))
	i = [hash2int[k] for k in path]
	scatter(x[1,:], x[2,:], color = i)
end

function sptn(d, n, l)
	m = DenseNode(ScaleShift(d),  MvNormal(d,1f0))
	for i in 1:l
		m = SumNode([DenseNode(SVDDense(2, identity, :butterfly), m) for i in 1:n])
	end
	return(m)
end

###############################################################################
#			non-normal mixtures
###############################################################################
xtrn = flower2(10000, npetals = 9)
xtst = flower2(10000, npetals = 9)

model = sptn(2, 9, 3)
logpdf(model, xtrn[:,1:100 ])

pa =  SumDenseProduct.samplepath(model)
SumDenseProduct.pathlogpdf(model, xtrn[:,1:100 ], pa)

history = fit!(model, xtrn, 100, 20000, 0; gradmethod = :exact, minimum_improvement = -1e10, opt = ADAM())
p = plot_contour(model, xtst, "spn - $(n)")
display(p)
println("sptn-$(n): mean log-likelihood= ",mean(logpdf(model, xtst)))
push!(sptn_models, model)


