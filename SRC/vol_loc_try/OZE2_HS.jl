using OrnsteinZernike  # Carga la biblioteca para las soluciones de Ornstein-Zernike
using JSON              # Carga para usar formato  JSON

function main(args...)
    try
        # user inputs
        phi_str = args[1][1]
        # println(phi_str) depende de phi
        phi = parse(Float64, phi_str)

        # Sistema de esferas duras
        dims = 3  # número de dimensiones
        kBT = 1.0 # menciona el número de kBT
        ρ = (6/pi) * phi  # rho depende de phi
        potential = HardSpheres(1.0)  # potencial de esfera dura
        system = SimpleLiquid(dims, ρ, kBT, potential)  # muestra el potencial para simpleLiquids().

        # Closure es la cerradura para la ecuación de Ornstein-Zernike
        closure = PercusYevick()

        # Resuelve el sistema utilizando la ecuación de Ornstein-Zernike
        sol = @time solve(system, closure)
        
        # Los parámetros dependientes de phi
        params = Dict("phi" => phi)  
        system = Dict("ID" => "HS", "params" => params)  # depende de los parámetros de esfera dura.

        # Procesa y guarda los resultados
        data = Dict("system_solution" => sol)
        
        # Diccionario con la ecuación de OZE
        output = Dict("system" => system, "OZE" => sol)

        # Imprime la solución en formato JSON
        output = JSON.json(output)
        println(output)
        
    catch 
        
        
        return 500
    end
end

main(ARGS)

