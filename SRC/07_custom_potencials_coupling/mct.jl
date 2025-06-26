using OrnsteinZernike
using ModeCouplingTheory
using Plots
using DelimitedFiles

const OZ = OrnsteinZernike
const MCT = ModeCouplingTheory

function main(args...)
    if length(args) < 10
        println("Se requieren 10 argumentos: σ z kBT φ M N_stages max_iter chi_list local_folder volume_folder")
        return
    end

    σ            = parse(Float64, args[1])
    z            = parse(Float64, args[2])
    kBT          = parse(Float64, args[3])
    φ            = parse(Float64, args[4])
    M            = parse(Int, args[5])
    N_stages     = parse(Int, args[6])
    max_iter     = parse(Int, args[7])
    chi_list     = parse.(Float64, split(args[8], ","))
    local_folder = args[9]
    volume_folder = args[10]

    mkpath(local_folder)
    mkpath(volume_folder)

    for χ in chi_list
        println(">> Procesando χ = $χ")

        # --- Parámetros del sistema
        κ = σ / 566.02
        p = (λB = 0.71432 / σ, σ = 1.0, κ = κ, z = -z)
        function Yukawa_R(r, p)
            κa = p.κ * 0.5 * p.σ
            LB = (p.z^2) * p.λB * exp(2 * κa) / (1 + κa)^2
            return LB * exp(-p.κ * r) / r
        end

        potential = OZ.CustomPotential(Yukawa_R, p)
        ρ = (6 / π) * φ
        system = OZ.SimpleLiquid(3, ρ, kBT, potential)
        closure = OZ.HypernettedChain()
        dr = 200.0 / M
        method = OZ.NgIteration(M = M; dr = dr, max_iterations = max_iter, N_stages = N_stages)
        method_ramp = OZ.DensityRamp(method, [ρ * χ])

        # --- Resolver OZ
        sol = OZ.solve(system, closure, method_ramp)[1]
        k = sol.k
        S = sol.Sk
        r = sol.r
        g = sol.gr

        # --- Guardar S(k) y g(r)
        base = "phi_$(replace(string(φ), "." => "_"))_chi_$(replace(string(χ), "." => "_"))"
        writedlm(joinpath(local_folder, "Sk_" * base * ".dat"), [k S])
        writedlm(joinpath(volume_folder, "Sk_" * base * ".dat"), [k S])
        writedlm(joinpath(local_folder, "gr_" * base * ".dat"), [r g])
        writedlm(joinpath(volume_folder, "gr_" * base * ".dat"), [r g])

        # --- Graficar S(k) y g(r)
        plot(k, S, xlabel="k", ylabel="S(k)", lw=2, title="S(k)")
        savefig(joinpath(local_folder, "Sk_" * base * ".svg"))
        savefig(joinpath(volume_folder, "Sk_" * base * ".svg"))

        plot(r, g, xlabel="r", ylabel="g(r)", lw=2, title="g(r)")
        savefig(joinpath(local_folder, "gr_" * base * ".svg"))
        savefig(joinpath(volume_folder, "gr_" * base * ".svg"))

        # --- Resolver MCT
        Nk = length(k)
        k_all = [k; k]
        S_all = [ones(Nk); S]
        ∂F0 = zeros(2 * Nk)
        α, β, δ = 0.0, 1.0, 0.0
        γ = @. k_all^2 / S_all
        kernel = MCT.SCGLEKernel(φ, k_all, S_all)
        equation = MCT.MemoryEquation(α, β, γ, δ, S_all, ∂F0, kernel)
        solver = MCT.TimeDoublingSolver(Δt=1e-5, t_max=1e10, N=8, tolerance=1e-8)

        sol_mct = MCT.solve(equation, solver)

        # --- Guardar y graficar Fs(k,t)
        idx = 25  # índice representativo
        t = MCT.get_t(sol_mct)[1:10:end]
        Fskt = MCT.get_F(sol_mct, 1:10:length(t)*10, idx) ./ S_all[idx]
        datos = [log10.(t) Fskt]
        writedlm(joinpath(local_folder, "Fskt_" * base * ".dat"), datos, header="log10(t) Fs(k,t)")
        writedlm(joinpath(volume_folder, "Fskt_" * base * ".dat"), datos, header="log10(t) Fs(k,t)")

        plot(log10.(t), Fskt, xlabel="log10(t)", ylabel="Fs(k,t)", lw=2, title="Fs(k,t)")
        savefig(joinpath(local_folder, "Fskt_" * base * ".svg"))
        savefig(joinpath(volume_folder, "Fskt_" * base * ".svg"))

        println(" Datos guardados para χ = $χ\n")
    end
end

main(ARGS...)

