using DelimitedFiles
using OrnsteinZernike

function save_data(nombre, formato; header = "", flag = true)
    @assert typeof(nombre) == typeof("hola") "El primer argumento debe ser texto"
    open(nombre, "w") do io
        if header != ""
            write(io, "# " * header * "\n")
        end
        writedlm(io, formato)
    end
    if flag println("Data saved as ", nombre) end
end

function main(args...)
    try
        ϵ = parse(Float64, args[1])
        σ = parse(Float64, args[2])
        n = parse(Int64, args[3])
        φ = parse(Float64, args[4])
        kBT = parse(Float64, args[5])
        local_folder = args[6]
        volume_folder = args[7]

        # Crear carpetas si no existen
        mkpath(local_folder)
        mkpath(volume_folder)

        potential = PowerLaw(ϵ, σ, n)
        dims = 3
        ρ = (6 / π) * φ
        system = SimpleLiquid(dims, ρ, kBT, potential)
        closure = HypernettedChain()
        sol = solve(system, closure)

        # Datos numéricos g(r)
        datos = [sol.r sol.gr]
        filename = "result_$(ϵ)_$(σ)_$(n)_$(φ)_$(kBT).dat"

        save_data(joinpath(local_folder, filename), datos, header = "r g(r)")
        save_data(joinpath(volume_folder, filename), datos, header = "r g(r)")

        # Resumen de parámetros
        resumen = [
            ["epsilon" ϵ];
            ["sigma" σ];
            ["n" n];
            ["phi" φ];
            ["rho" ρ];
            ["kBT" kBT];
            ["puntos" length(sol.r)]
        ]

        resumen_name = "resumen_parametros.dat"
        save_data(joinpath(local_folder, resumen_name), resumen, header = "Parámetro Valor")
        save_data(joinpath(volume_folder, resumen_name), resumen, header = "Parámetro Valor")

    catch error
        @error " Error resolviendo el sistema: $error"
    end
end

main(ARGS...)
