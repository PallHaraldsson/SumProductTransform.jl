using Clustering

function initpp!(m::DenseNode, X, shared = :none)
	xx = _initpp!(m, X)
	initpp!(m.p, X, shared)
end

function _initpp!(m::DenseNode, X)
	m.m.b .= - mean(X, dims = 2)[:]
	m.m.u.θs .= 0
	m.m.v.θs .= 0
	d = 1 ./ std(X, dims = 2)[:]
	d[isnan.(d)] .= 1
	d[isinf.(d)] .= 1
	m.m.d.d .= d
	m.m(X)
end

function initpp!(m::SumNode, X, shared)
	R = kmeans(X, length(m.components); maxiter=20, display=:none)
	if shared == :none
		for i in 1:length(m.components)
			xx = _initpp!(m.components[i], X[:, assignments(R) .== i])
			initpp!(m.components[i].p, xx, shared)
		end
	else
		xxs = [_initpp!(m.components[i], X[:, assignments(R) .== i]) for i in 1:length(m.components)]
		xx = reduce(hcat, xxs)
		initpp!(m.components[1].p, xx, shared)
	end
end


initpp!(::MvNormal, X, shared) = nothing