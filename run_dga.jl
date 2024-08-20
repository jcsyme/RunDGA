
# activate the environment first
using Distributed
@everywhere using Pkg

# initialize path
try

    @everywhere path = dirname(@__FILE__)
    @everywhere Pkg.activate(path)
    
    # load some code
    include(joinpath(path, "src", "yaml_configuration.jl"))
    include(joinpath(path, "src", "dga_support.jl"))

catch e
    error("Error instantiating support functions: $(e)")

end



# see https://docs.julialang.org/en/v1/manual/faq/#man-scripting for info on scripting in Julia
if abspath(PROGRAM_FILE) == @__FILE__
    main!(dirname(@__FILE__))
end
