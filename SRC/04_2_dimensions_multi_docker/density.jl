using DelimitedFiles
using OrnsteinZernike

function save_data(nombre, formato; header = "", flag = true)
    @assert typeof(nombre) == String ""
    open(nombre, "w") do io
        if header != ""
            write(io, "# " * header * "\n")
        end
        writedlm(io, formato)
    end
    if flag
        println("Data saved as ", nombre)
    end
end

function main(args...)
    if length(args) < 5
        @error "Se requieren 5 argumentos: densities_csv, dimension, kBT, local_folder, volume_folder"
        return
    end

    try
        densities_csv = args[1]
        dimension = parse(Int, args[2])
        kBT = parse(Float64, args[3])
        local_folder = args[4]
        volume_folder = args[5]

        densities = parse.(Float64, split(densities_csv, ","))

        mkpath(local_folder)
        mkpath(volume_folder)

        potential = HardSpheres(1.0)

        puntos = 0  

        for density in densities
            println("Resolviendo para densidad = $density")

            try
                system = SimpleLiquid(dimension, density, kBT, potential)
                closure = PercusYevick()
                sol = solve(system, closure)

                filename = "result_density_$(replace(string(density), "." => "_")).dat"
                header = "r g(r)"
                data = [sol.r sol.gr]

                save_data(joinpath(local_folder, filename), data, header=header)
                save_data(joinpath(volume_folder, filename), data, header=header)

                puntos = length(sol.r) 

            catch inner_error
                @error "Error resolviendo sistema para densidad $density: $inner_error"
            end
        end

        if puntos > 0
            resumen = [
                ["densities" densities_csv];
                ["dimension" dimension];
                ["kBT" kBT];
                ["puntos" puntos]
            ]

            resumen_name = "resumen_parametros.dat"
            save_data(joinpath(local_folder, resumen_name), resumen, header="Parámetro Valor")
            save_data(joinpath(volume_folder, resumen_name), resumen, header="Parámetro Valor")
        else
            @warn "No se pudo resolver ninguna densidad. No se generó resumen."
        end

    catch error
        @error "Error general resolviendo el sistema: $error"
    end
end

main(ARGS...)

#export DENSITIES=0.11,0.21,0.31,0.41,0.51,0.61,0.7;export DIMENSION=2; export KBT=1.0;  export N_STAGES=10; export FOLDER_NAME=nuevo1; docker compose up --build --force-
#$env:DENSITIES="0.11,0.21,0.31,0.41,0.51,0.61,0.7"; $env:DIMENSION="2"; $env:KBT="1.0"; $env:N_STAGES="10"; $env:FOLDER_NAME="dimensions"; docker compose up --build --force-recreate
#DENSITIES="0.11,0.21,0.31,0.41,0.51,0.61,0.7"; DIMENSION="2"; KBT="1.0"; N_STAGES="10"; FOLDER_NAME="dimensions"; docker compose up --build --force-recreate
#mac_1DENSITIES="0.11,0.21,0.31,0.41,0.51,0.61,0.7" \DIMENSION="2" \KBT="1.0" \N_STAGES="10" \FOLDER_NAME="dimensions" \docker compose up --build --force-recreate
