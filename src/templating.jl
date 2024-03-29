export newTemplate, render2file
################################################################
"""
    newTemplate(name)

Create new destination html file as the template

    newTemplate(name, :function)

Prints a function to be used as a template

# Examples
```julia
# you can create a file and edit the file directly by using
newTemplate("person")

## create person function to store out html template
newTemplate("person", :function)
```
"""
function newTemplate(name, type::Symbol = :file, template::Union{String,Nothing} = nothing)

    if type == :file

        try
            mkpath(joinpath("app", "destination"))
        catch e

        end
        filePath = joinpath("app", "destination", "$(name).html")
        touch(filePath)

        if !isnothing(template)

            file = open(filePath, "w")
            print(file, template)
            close(file)

        else # open file in Atom for editing
            if !isdefined(Main, :Atom)
                Atom.edit(filePath)
            end
        end

    elseif type == :function

        if !isnothing(template) # doesn't work because $ are evaluated outside of the function
            prt = template
        else
            prt = """
            # enter your html code here
            # use \$() to evaluate julia variables or code
            """
        end

    # todo: append this to controller file
        println("""

        function $(name)(; put_variables_here)

        # use your any julia code here to control the outputed html string.

        \"\"\"
        $prt
        \"\"\"

        end
        """)

    end

end
################################################################

"""
    render2file(destination, overwrite, var...)

render variables passed as an input to the destination file.

You should put \$(var) in the destination file/string so var is evaluated there. Pass the variables as keyword arguments with the same name you used in the html string/file. Variables should be string,

If you want to statically overwrite the file pass `true` as the 2nd argument to the function. Useful if you don't want a dynamic website.

# Examples
```julia
# Add the following html code to the generated html file
#=
<person id=\$(id)>
  <age>\$(age)</age>
  <study-field>\$(field)</study-field>
  <GPA>\$(GPA)</GPA>
  <taken-courses>\$(courses[1])</taken-courses>
  <taken-courses>\$(courses[2])</taken-courses>
</person>
=#

# Specify the template (or its path), and also the variables for rendering
out =render2file("person", false,
  id = 1,
  age = 24,
  field = "Mechanical Engineering",
  GPA = 4.5,
  courses = ["Artificial Intelligence", "Robotics"])

# you pass `true` as the 2nd argument to owerwrite person.html statically.

```
"""
function render2file(destination::String, overwrite::Bool=false; var...)

    local file, destinationString, s

    # creates variables from keywords inputed to the function
    for key in keys(var)
        @eval $key = multiString($(var[key]))
    end

    # reading string from html file
    if ispath(destination)

        try
            filePath = destination
            file = open(filePath, "r")
            destinationString = read(file, String)

        catch e
            error("destination file address is not correct")
        end

    else
        filePath = joinpath("app", "destination", "$(destination).html")
        file = open(filePath, "r")
        destinationString = read(file, String)
    end



    try
        s = '"' * '"' * '"' * destinationString * '"' * '"' * '"'
    catch e
        s = destinationString
    end

    # evaluate $() values in the string
    out = eval(Meta.parse(s))

    if overwrite
        print(file, out)
    end
    close(file)

    return out
end

################################################################
# Multi-Stringer

multiString(var::String) = var
multiString(var::Union{Number,Bool}) = string(var)

function multiString(var::Array{T}) where {T<:Union{String, Number, Bool}}

    varNum=length(var)

    # out = NTuple{varNum,String}

    out = Array{String}(undef,varNum)

    for i = 1:varNum
        out[i] = string(var[i])
        # Base.setindex!(out,var[i],i)
    end

    return out
end

function multiString(var::NTuple{N,T}) where {T<:Union{String, Number, Bool}} where{N}

    # out = NTuple{N,String}
    out = Array{String}(undef,N)

    for i = 1:N
        out[i] = string(var[i])
        # Base.setindex!(out,var[i],i)
    end

    return Tuple(out)
end
################################################################
