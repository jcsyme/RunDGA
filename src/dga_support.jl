@everywhere using ArgParse
@everywhere using DataFrames
@everywhere using DiscreteGraphAlgorithms
@everywhere using GraphDistanceAlgorithms
@everywhere using GraphFragments
@everywhere using IterativeHeaps
@everywhere using SparseArrays


"""
Retrieve the algorithms that are to be run
"""
function get_algorithms(
    dict_args::Dict,
)
    all_algs = DiscreteGraphAlgorithms.all_dga_prefixes

    # try to retrieve algorithm
    algs_specified = get(dict_args, "algorithms", nothing)
    isa(algs_specified, Nothing) && error("Error in get_algorithms(): no valid algorithms found.")

    # check if all
    (algs_specified == "all") && (return all_algs)

    # otherwise split
    algs_specified = String.(split(algs_specified, ","))
    algs_specified = [x for x in all_algs if String(x) in algs_specified]
    (length(algs_specified) == 0) && (algs_specified = nothing)
    
    return algs_specified
end



function get_configuration(
    path::String,
    nm::String = "config.yaml",
)
    # error handling done in the object
    config = YAMLConfiguration(joinpath(path, nm))

    return config
end



"""
Retrieve the graph to operate on
"""
function get_graph(
    fp::Union{String, Nothing};
    kwargs...
)   
    # some checks
    !isa(fp, String) && error("Invalid file path: the path must be a string.")
    !ispath(fp) && error("Path '$(fp)' does not exist.")

    graph_wrapper = read_egl(fp; kwargs...)
    d = graph_wrapper.dims

    @info "Graph successfully retrieved from '$(fp)':\n\t$(d[1]) vertices\n\t$(d[2]) edges\n"

    return graph_wrapper
end



"""
Get the OptimizationParameters object that will be used

##  Returns

Tuple of the form

    (
        dict_default_op,  # dictionary of default OptimizationParameters field values
        dict_op_by_alg,  # dictionary of OptimizationParameters field values by algorithm
        dict_opts,  # dictionary to be passed to OptimizationParameters as `opts`
        op,  # OptimizationParameters object
    )

"""
function get_optimization_parameters(
    dict_args::Dict,
    graph_wrapper::GraphWrapper,
    config::YAMLConfiguration,
)
    # get configuration options, including dictionary of opts, OptimizationParameter (ops) fields by algorithm, and some defaults for iterations
    dict_opts, dict_op_by_alg = get_opts_from_config(config; )
    max_iter_def = get(config, "global.max_iter", 1000)

    max_iter_no_improvement_def = get(config, "global.max_iter_no_improvement", 200)
    dict_default_op = Dict{Symbol, Any}(
        :max_iter => max_iter_def,
        :max_iter_no_improvement => max_iter_no_improvement_def,
    )

    # retrieve and check the number of vertices
    n_vertices = tryparse(Int64, get(dict_args, "num-vertices", nothing))
    isa(n_vertices, Nothing) && error(
        "Invalid solution set size $(n_vertices): the value must be parsable as an Integer."
    )
    ((n_vertices < 1) | (n_vertices >= graph_wrapper.dims[1]))  && error(
        "Invalid solution set size $(n_vertices): the value must be at least one and less than $(graph_wrapper.dims[1]), the number of vertices in the graph."
    )


    op = OptimizationParameters(
        n_vertices,
        graph_wrapper;
        max_iter = max_iter_def,
        max_iter_no_improvement = max_iter_no_improvement_def,
        opts = dict_opts,
    )

    out = (
        dict_default_op,
        dict_op_by_alg,
        dict_opts,
        op,
    )

    return out
end



"""
Retrieve OptimiztionParameter `opts` dictionary from the YAMLConfiguration

Returns two dictionaries:

    1. `dict_opts`: dictionary of options for OptimiztionParameters
    2. `dict_op_by_alg`: dictionary mapping each algorithm to 
        OptimizationParameters fields for each run

"""
function get_opts_from_config(
    config::YAMLConfiguration;
    keys_symbol::Vector{Symbol} = Vector{Symbol}([
        :aco_heuristic
    ])
)
    # return two dictionaries
    dict_opts = Dict{Symbol, Any}()
    dict_op_by_alg = Dict{Symbol, Dict{Symbol, Any}}()

    # iterate over all algorithms available
    for alg in DiscreteGraphAlgorithms.all_dga_prefixes

        dict_retrieve = get(config, alg)
        isa(dict_retrieve, Nothing) && continue
        
        # 
        dict_retrieve_opts = Dict{Symbol, Any}(
            (Symbol("$(alg)_$(k)"), v) for (k, v) in dict_retrieve
            if !(Symbol(k) in fieldnames(OptimizationParameters))
        )

        dict_retrieve_op = Dict{Symbol, Any}(
            (Symbol(k), v) for (k, v) in dict_retrieve
            if (Symbol(k) in fieldnames(OptimizationParameters))
        )

        # add to outer dicts
        merge!(dict_opts, dict_retrieve_opts)
        dict_op_by_alg[alg] = dict_retrieve_op
    end

    # update 
    for (k, v) in dict_opts
        !(k in keys_symbol) && continue
        dict_opts[k] = Symbol(v)
    end

    out = (dict_opts, dict_op_by_alg)

    return out
end



"""
Retrieve a trivial graph to use to help develop parameters
"""
function get_trivial_graph_op()
    
    # pull the Borgatti example
    examples = GraphFragments.Examples()
    df = sparse(examples.get_example(:borgatti_figure_5a))
    df = findnz(df)
    df = DataFrame(
        Dict(
            :i => df[1],
            :j => df[2]
        )
    )

    # convert to a graph wrapper
    graph_wrapper_basic = df_to_graph_wrapper(df, :i, :j, )
    
    # build an optimization parameters obj
    op = OptimizationParameters(
        3,
        graph_wrapper_basic;
        max_iter = 1000,
        max_iter_no_improvement = 100,
    )
    
    return op
end



"""
Retrieve the indices of vertices specified by name in command line
"""
function get_vertex_names(
    names::Union{String, Nothing};
    delim::String = ",",
)
    nothing
end



"""
Main function run in run_dga. `path` is the directory path where run_dga.jl 
    sits.
"""
function main!(
    path::String,
)  

    @info("Running DiscreteGraphAlgorithms with:\n\tThreads:\t$(Threads.nthreads())\n\tProcesses:\t$(nprocs())")
    
    ##  INITIALIZATION

    # get arguments and configuration
    dict_args = parse_commandline()
    config = get_configuration(path, )
    
    # get the graph
    fp = get(dict_args, "file-sparse-adjmat", nothing)
    graph_wrapper = get_graph(fp)
    
    # get the algorothm and optimization parameters, which govern the objective function, the number of nodes to identify, and any algorithm params that are passed
    algs = get_algorithms(dict_args)
    (
        dict_default_op,
        dict_op_by_alg,
        dict_opts,
        op,
    ) = get_optimization_parameters(
        dict_args,
        graph_wrapper,
        config,
    )


    # try running with a trivial graph first
    op_trivial = get_trivial_graph_op()
    
    @info "Trying trivial graphs for precompilation"
    run_algorithms!(
        algs,
        op_trivial,
        Dict(
            :max_iter => op_trivial.max_iter,
            :max_iter_no_improvement => op_trivial.max_iter_no_improvement
        ),
        Dict(),
        Dict();
        verbose = false,
    )
    

    # get the algorithms that are specified
    @info "Starting algorithms on graphs"
    run_algorithms!(
        algs,
        op,
        dict_default_op, 
        dict_op_by_alg,
        dict_opts,
    )

    return nothing

end



"""
Build arguments for the script
"""
function parse_commandline()
    # based off of readthedocs intro:
    #
    # https://argparsejl.readthedocs.io/en/latest/argparse.html
    s = ArgParseSettings()
    
    @add_arg_table s begin

        #"--opt1"
        #    help = "an option with an argument"
        "--algorithms"
            help = "Specify the algorithms to run on the graph. If running,"
            arg_type = String
            default = "all"
        "--n-workers"
            help = "Specify the number of workers to use. Can be an integer or 'auto' (default) to use all available workers. Bounded by the number of available cores on the machine--uses asynchronous paralleliation, not multi-threading."
            default = "auto"
        "--save-output"
            help = "Save output to file? If false, then no output file is stored. If true, then, by default, an ouput is saved to the working directory."
            action = :store_true
        #"--flag1"
        #    help = "an option without argument, i.e. a flag"
        #    action = :store_true
        "file-sparse-adjmat"
            help = "Path to a file containing the sparse adjacency matrix. This file should take the following form..."
            required = true
        "num-vertices"
            help = "Size of the solution set |S| of vertices to identify using DiscreteGraphAlgorithms."
            required = true
    end

    dict_args = parse_args(s)

    #=
    for (k, v) in dict_args
        println("$k -> $v")
    end
    =#

    return dict_args
end




"""
Run the algorithms and generate information from them
"""
function run_algorithms!(
    algs::Vector{Symbol},
    op::OptimizationParameters,
    dict_default_op::Dict, 
    dict_op_by_alg::Dict,
    dict_opts::Dict;
    verbose::Bool = true,
)

    for alg in algs
        
        ##  UPDATE OPTIMIZATION PARAMETERS

        # get any OptimizationParameters fields associated with this algorithm
        dict_op_cur_alg = get(dict_op_by_alg, alg, Dict())
        
        # max iterationss
        max_iter = get(
            dict_op_cur_alg, 
            :max_iter, 
            get(dict_default_op, :max_iter, nothing)
        )

        # max iterations without improvement
        max_iter_no_improvement = get(
            dict_op_cur_alg, 
            :max_iter_no_improvement, 
            get(dict_default_op, :max_iter_no_improvement, nothing)
        )
        
        # update
        !isa(max_iter, Nothing) && (op.max_iter = max_iter)
        !isa(max_iter_no_improvement, Nothing) && (op.max_iter_no_improvement = max_iter)
        

        ##  RUN ONCE WITH 1 ITERATION TO PRECOMPILE
        
        # get the iterand
        iterand = eval(Symbol("$(alg)_iterand"))

        #=
        op.max_iter = 1
        @time DiscreteGraphAlgorithms.iterate(
            iterand,
            op;
            log_interval = nothing,
        )
        =#

        ##  FULL IMPLEMENTATION

        op.max_iter = max_iter
        @time result = DiscreteGraphAlgorithms.iterate(
            iterand,
            op;
            log_interval = nothing,
        )

        # some info
        vertices_best = copy(op.graph_wrapper.vertex_names[result[2]])
        sort!(vertices_best)
        pushfirst!(vertices_best, "")
        vertices_best = join(vertices_best, "\n\t")

        verbose && (@info "Algorithm $(alg) complete with objective value $(result[1]).\nBest set:$(vertices_best)\n\n")
    end

end

