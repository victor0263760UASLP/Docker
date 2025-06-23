

using OrnsteinZernike  #carga la biblioteca para las soluciones de OrnsteinZernick
using JSON        # carga para usar JSON

function main(args...)
    # user inputs
    phi_str = args[1][1]
    #println(phi_str) depende de phi
    phi = parse(Float64, phi_str)

    # sistema  esferas duras
    dims = 3  # numero de dimensiones
    kBT = 1.0 #menciona el numero de kBT
    ρ = (6/pi)*phi #rho depende de phi
    potential = HardSpheres(1.0)  # potencial de esfera dura
    system = SimpleLiquid(dims, ρ, kBT, potential) #muestra el potencial para simpleLiquids().

    # closure es la cerradura  para la ecuacion de  Ornstein-Zernike 
    closure = PercusYevick()

    # resuelve el sistema utilizando la ecuacion de ornstein zernick
    sol = @time solve(system, closure)
    params = Dict("phi" => phi) #los parametros depedientes de phi
    system = Dict("ID" => "HS", "params" => params) # depende de los parametros de esfera dura.
    #json_system = JSON.json(system)

    # procesa y guarda los resultados
    data = Dict("system_solution" => sol)
    #json_data = JSON.json(data)
    output = Dict("system" => system, "OZE" => sol) #diccionario en la ecuacion de OZE


    # imprime la solucion en formato JSON
    output = JSON.json(output)
    println(output)
end

main(ARGS)
# docker run --rm -e PARAM=0.2 oze
#julia .\OZE2_HS.jl 0.3