using DelimitedFiles, JuMP, Gurobi, Pkg, Graphs, GraphPlot, Colors, Cairo, Fontconfig


# Read the adjacency matrix from a text file
function read_adjacency_matrix(path::String)
    # Open the file for reading
    lines = readlines(path)
    
    # Extract values from each line and construct the adjacency matrix
    A = [parse(Int, v) for line in lines for v in split(replace(line, r"[\[\]]" => ""))]
    
    # Reshape the vector to a matrix
    n = Int(sqrt(length(A)))
    return reshape(A, n, n)
end

# {k,k+1}-Factor optimization model
function factor_graph(adj_matrix,k)
    n = size(adj_matrix, 1)  # number of vertices of the graph
    model = Model(Gurobi.Optimizer)  

    # Variables: x[i, j] is 1 if edge (i, j) is in the subgraphestá {k,k+1}-factor, 0 otherwise
    @variable(model, x[1:n, 1:n], Bin)

    # Degree condition: Each vertex must have degree k or k+1
    for i in 1:n
        @constraint(model, k <= sum(x[i, j] for j in 1:n if adj_matrix[i, j] == 1) <= k+1)
    end

    # Symmetry condition: x[i, j] is equal to x[j, i]
    for i in 1:n
        for j in i+1:n
            if adj_matrix[i, j] == 1
                @constraint(model, x[i, j] == x[j, i])
            else 
                @constraint(model, x[i, j] == 0)
             end
        end
    end

    # Objetive function: Maximize the number of edges in the subgraph
    @objective(model, Max, sum(x[i, j] for i in 1:n for j in 1:n if adj_matrix[i, j] == 1))

    # Solve the model
    optimize!(model)

    return model
   
end

# Main function to execute the program
function main(path::String,  k)

    A = read_adjacency_matrix(path)
    model = factor_graph(A, k)
    
    # Check if the solution was found
    if termination_status(model) == MOI.OPTIMAL
        println("Subgraph {$(k),$(k+1))}-factor found.")
        for i in 1:size(A,1)
            for j in i+1:size(A,1)
                if i != j
                    if value(model[:x][i,j]) > 0.5
                        println("Edge ($(i - 1),$(j - 1)) belongs to the subgraph")
                    end
                end
            end
        end
        return model
        #return [value(x[i, j]) for i in 1:n, j in 1:n]
    else
        println("The graph has not a {$(k),$(k+1)}-fator.")
        return nothing
    end
end


path = "D:\\GitHub - Projects\\Factorization\\teste.txt"

main(path,1)
