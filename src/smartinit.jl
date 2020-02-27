using Clustering, IterTools

function removenothing(x)
	mask = isnothing.(x)
	!any(mask) && return(x)
	mask = sum(mask, dims = 1) .== 0
	xx = x[:, mask[:]]
	Float64.(xx)
end

initpath!(m, x, path; bs = 100, nsteps = 1000, verbose::Bool = false) = initpath!(m, x, path, Flux.params(m); bs = 100, nsteps = 1000, verbose = false)

function initpath!(m, x, path, ps; bs = 100, nsteps = 1000, verbose::Bool = false)
	verbose && @show pathlogpdf(m, x, path)
	d, l = size(x)
	l == 0 && return(x)
	data = repeatedly(() -> (x,), nsteps)
	Flux.train!(xx -> - mean(pathlogpdf(m, xx, path)), ps, data, ADAM())
	verbose && @show pathlogpdf(m, x, path)
end


function initpath!(m, x, path::Vector, ps; bs = 100, nsteps = 1000, verbose::Bool = false)
	verbose && @show mean(batchpathlogpdf(m, x, path))
	d, l = size(x)
	l == 0 && return(x)
	data = repeatedly(() -> (x,), nsteps)
	Flux.train!(xx -> - mean(batchpathlogpdf(m, xx, path)), ps, data, ADAM())
	verbose && @show mean(batchpathlogpdf(m, x, path))
end

function _initpath!(m, x, path, ps; bs = 100, nsteps = 1000, verbose::Bool = false)
	verbose && @show pathlogpdf(m, x, path)
	for i in 1:nsteps
		gs = gradient(() -> mean(pathlogpdf(m, xx, path)), ps)
		any([any(isnan.(gs[p])) for p in ps]) && serialize("/tmp/debug/jls", (m, xx, path, ps))
		any([any(isinf.(gs[p])) for p in ps]) && serialize("/tmp/debug/jls", (m, xx, path, ps))
		Flux.Optimise.update!(opt, ps, gs)
	end
	verbose && @show pathlogpdf(m, x, path)
end
