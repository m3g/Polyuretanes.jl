module Polyuretanes

using Catalyst
using DifferentialEquations

export fit
export simulate
export plot_OH

function score(sim,experimental_data,sim_col)
  score = 0.
  p = getindex.(sim.u,sim_col)
  for (t,val) in eachrow(experimental_data)
    i = findfirst(ts -> ts > t, sim.t)
    dpdt = (p[i]-p[i-1])/(sim.t[i]-sim.t[i-1])
    pred_at_t = p[i-1] + dpdt * (t-sim.t[i-1]) 
    score += (val - pred_at_t)^2
  end
  return score
end

function objective_function(p,ode_problem,experimental_data,sim_col)
  f = try 
    sim = solve(ode_problem,p=p,verbose=false)
	  score(sim,experimental_data,sim_col)
  catch
    +Inf
  end
  return f
end

function fit_parameters(p0,c0,tspan,reaction_network,experimental_data;max_failed_trials=10000)
	x = [values(p0)...]
	c0 = [values(c0)...]
	ode_problem = ODEProblem(reaction_network,c0,tspan,x)
	# the fourth column corresponds to the OH concentration
	f(x) = objective_function(x,ode_problem,experimental_data,4)

  xtrial = copy(x)
  failed_trials = 0
  step = 0.1
  fbest = objective_function(xtrial,ode_problem,experimental_data,4)
  while failed_trials < max_failed_trials
    irand = rand(1:length(x))
    xtrial[irand] = x[irand] + -step*x[irand] + 2*step*x[irand]*rand()
    ftrial = objective_function(xtrial,ode_problem,experimental_data,4)
    if ftrial < fbest
      failed_trials = 0
      x .= xtrial
      fbest = ftrial
      @show fbest, step
    else 
      failed_trials += 1
    end
  end
  return fbest, x
end

function simulate(p0,c0,tspan,reaction_network)
	x = [values(p0)...]
	c0 = [values(c0)...]
	ode_problem = ODEProblem(reaction_network,c0,tspan,x)
  sim = solve(ode_problem,p=x)
  return sim
end

vap(OH,A,b,c) = A*exp((OH-b)/c)

function reaction()
  reaction = @reaction_network begin
    (k1,km1), U <--> NCO + DIPA_l
    k2, NCO + OH --> POL
    vap(OH,A,b,c), DIPA_l --> DIPA_v
  end k1 km1 k2 A b c
  return reaction 
end

struct Result
  sys
  sim
  score
  x
end

function Base.show(io::IO,r::Result)
  println("Score = ", r.score)
  println("Parameters: ")
  names = keys(r.sys.p0)
  for i in eachindex(r.x)
    println("    ",names[i]," = ",r.x[i])
  end
end

function fit(sys;max_failed_trials=10000)
  reaction_network = reaction()
  p0 = sys.p0
  c0 = sys.c0
  tspan = sys.tspan
  experimental_data = sys.experimental_data
  fbest, xbest = fit_parameters(
    p0,c0,tspan,reaction_network,experimental_data,
    max_failed_trials=max_failed_trials
  )
  sim = simulate(xbest,c0,tspan,reaction_network)
  return Result(sys, sim, fbest, xbest)
end

function plot_OH(result) 
  sim = result.sim
  experimental_data = result.sys.experimental_data
  Main.default(fontfamily="Computer Modern",
        linewidth=2, framestyle=:box, label=nothing, grid=false)
  Main.scalefontsizes()
  Main.scalefontsizes(1.2)
	plt = Main.plot()
	Main.plot!(plt,
		sim.t,getindex.(sim.u,4),
		xlabel="time / s",
		ylabel="[OH]",
		label="Simulation"
	)
	Main.scatter!(plt,
		experimental_data[:,1],
		experimental_data[:,2],
		label="Experimental"
	)
	return plt
end

function datasets()

BD_IPDI_110C_025 = (
  experimental_data = readdlm("./data/bd_ipdi_110C_0.25.dat"),
  c0 = ( U = 5.01, NCO = 1.67, DIPA_l = 0.,	OH = 6.68, POL = 0., DIPA_v = 0.),
  p0 = ( k1 = 6.8e-6, km1 = 4.5e-4, k2 = 7.7e-5, A = 2.77e-4, b = 2.70058, c = 0.49081),
  tspan = (0.,350e3)
)

BD_IPDI_110C_050 = (
  experimental_data = readdlm("./data/bd_ipdi_110C_0.5.dat"),
  c0 = ( U = 5.01, NCO = 1.67, DIPA_l = 0.,	OH = 6.68, POL = 0., DIPA_v = 0.),
  p0 = ( k1 = 6.8e-6, km1 = 4.5e-4, k2 = 7.7e-5, A = 2.77e-4, b = 2.70058, c = 0.49081),
  tspan = (0.,350e3)
)

BD_IPDI_110C_100 = (
  experimental_data = readdlm("./data/bd_ipdi_110C_1.0.dat"),
  c0 = ( U = 5.01, NCO = 1.67, DIPA_l = 0.,	OH = 6.68, POL = 0., DIPA_v = 0.),
  p0 = ( k1 = 6.8e-6, km1 = 4.5e-4, k2 = 7.7e-5, A = 2.77e-4, b = 2.70058, c = 0.49081),
  tspan = (0.,350e3)
)

end

end # module