# Testing discrete univariate distributions

using Distributions
import JSON
using Base.Test


function verify_and_test_discretes(jsonfile, n_tsamples::Int)
    R = JSON.parsefile(jsonfile)
    for (ex, dct) in R
        println("    testing $(ex)")

        # check type
        dtype = eval(symbol(dct["dtype"]))
        @assert isa(dtype, Type) && dtype <: DiscreteUnivariateDistribution
        d = eval(parse(ex))
        @test isa(d, dtype)

        # verification and testing
        verify_and_test(d, dct, n_tsamples)
    end
end

function verify_and_test(d::DiscreteUnivariateDistribution, dct::Dict, n_tsamples::Int)
    # verify parameters
    pdct = dct["params"]
    for (fname, val) in pdct
        f = eval(symbol(fname))
        @assert isa(f, Function)
        Base.Test.test_approx_eq(f(d), val, "$fname(d)", "val")
    end

    # verify stats
    r_min = dct["minimum"]
    r_max = dct["maximum"]
    r_min = r_min == "-inf" ? -Inf : r_min
    r_max = r_max == "inf" ? Inf : r_max

    @test_approx_eq minimum(d) r_min
    @test_approx_eq maximum(d) r_max
    @test_approx_eq mean(d) dct["mean"]
    @test_approx_eq var(d) dct["var"]
    @test_approx_eq_eps median(d) dct["median"] 1.0

    if applicable(entropy, d)
        @test_approx_eq_eps entropy(d) dct["entropy"] 1.0e-7
    end

    # verify quantiles
    @test_approx_eq quantile(d, 0.10) dct["q10"]
    @test_approx_eq quantile(d, 0.25) dct["q25"]
    @test_approx_eq quantile(d, 0.50) dct["q50"]
    @test_approx_eq quantile(d, 0.75) dct["q75"]
    @test_approx_eq quantile(d, 0.90) dct["q90"]

    # verify logpdf and cdf at certain points
    pts = dct["points"]
    for pt in pts
        x = int(pt["x"])
        lp = float64(pt["logpdf"])
        cf = float64(pt["cdf"])
        Base.Test.test_approx_eq(logpdf(d, x), lp, "logpdf(d, $x)", "lp")
        Base.Test.test_approx_eq(cdf(d, x), cf, "cdf(d, $x)", "cf")
    end

    # generic testing
    test_distr(d, n_tsamples)
end


## main

jsonfile = joinpath(dirname(@__FILE__), "discrete_test.json")
verify_and_test_discretes(jsonfile, 10^6)

