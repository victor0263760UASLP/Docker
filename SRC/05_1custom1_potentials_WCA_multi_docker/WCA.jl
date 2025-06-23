using OrnsteinZernike: PercusYevick, HypernettedChain, CustomPotential, SimpleLiquid, NgIteration, solve

using DelimitedFiles

function save_data(nombre, formato; header = "", flag = true)
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

function get_closure(closure_str)
    closure_str = lowercase(strip(closure_str))
    closure_map = Dict(
        "percusyevick" => PercusYevick(),
        "py"           => PercusYevick(),
        "HypernettedChain" => HypernettedChain(),
        "hnc"              => HypernettedChain()
    )
    if haskey(closure_map, closure_str)
        return closure_map[closure_str]
    else
        error("Cerradura no reconocida: '$closure_str'")
    end
end

function LJT(r, p)
    σ = p.σ
    return r <= (2^(1/6))*σ ? 4.0*p.ϵ * ((σ/r)^12 - (σ/r)^6) + p.ϵ : 0.0
end

function main(args...)
    if length(args) < 6
        @error "Se requieren 6 argumentos: ϕ kBT σ ϵ local_folder closure_str"
        return
    end

    ϕ = parse(Float64, args[1])
    kBT = parse(Float64, args[2])
    σ = parse(Float64, args[3])
    ϵ = parse(Float64, args[4])
    local_folder = args[5]
    closure_str = args[6]

    println("DEBUG: closure_str raw = '$closure_str'")
    closure_str = lowercase(strip(closure_str))
    println("DEBUG: closure_str cleaned = '$closure_str'")

    mkpath(local_folder)

    p = (σ = σ, ϵ = ϵ)
    potential = CustomPotential(LJT, p)

    dims = 2
    ρ = (4/π)*ϕ

    system = SimpleLiquid(dims, ρ, kBT, potential)
    closure = get_closure(closure_str)
    method = NgIteration()

    sol = solve(system, closure, method)

    phi_str = replace(string(round(ϕ, digits=4)), "." => "p")

    save_data(joinpath(local_folder, "gdr_phi_"*phi_str*".dat"),
              hcat(sol.r, sol.gr), header="r g(r)")
    save_data(joinpath(local_folder, "sdk_phi_"*phi_str*".dat"),
              hcat(sol.k, sol.Sk), header="k S(k)")
end

main(ARGS...)

