# a simple YAML configuration
using YAML


import Base:
    get



#################################
#    BUILD THE CONFIGURATION    #
#################################

"""
Initialize a configuration from a YAML file. 

Initialization Arguments
------------------------
- fp: file path to YAML file to read in
"""
struct YAMLConfiguration
    dict_yaml::Dict
    path::String
    
    function YAMLConfiguration(
        path::String;
    )
        
        dict_yaml = nothing

        # try retrieving the yaml dictionary
        try
            dict_yaml = YAML.load_file(path)
        catch e
            error("Error initializing YAML dictionary in YAMLConfiguration: $(e)")
        end

        return new(
            dict_yaml,
            path,
        )
    end
end
    


"""
Allow for recursive retrieval of dictionary values from a YAMLConfiguration.
    Nested keys are stored using delimiters.

Function Arguments
------------------
- key: key that represents YAML nesting. Levels are seperated by delim, 
    e.g., to access

    dict_yaml.get("level_1").get("level_2")

    use 

    YAMLConfig.get("level_1.level_2")

Keyword Arguments
-----------------
- delim: delimeter to use in get
- return_on_none: optional value to return on missing value. 
"""
function get(
    config::YAMLConfiguration,
    key::Union{String, Symbol},
    return_on_none::Union{Nothing, String, Real} = nothing;
    delim::String = ".",
)
    
    !isa(key, String) && (key = String(key);)

    # split keys into path and initialize value
    keys_nested = split(key, delim)
    value = config.dict_yaml
    subkey = nothing
    
    # iterate down the tree
    for k in keys_nested
        subkey = k
        value = get(value, k, nothing)
        !isa(value, Dict) && break
    end
    
    # verify that the value is good
    test = (subkey == keys_nested[end]) & !isa(value, Nothing)
    value = test ? value : return_on_none

    return value
end
