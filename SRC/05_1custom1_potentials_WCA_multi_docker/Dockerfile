FROM julia:1.11

RUN apt-get update && apt-get install -y \
    bash curl wget git build-essential libcurl4-openssl-dev ca-certificates dos2unix \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

# Clonar OrnsteinZernike.jl
RUN git clone https://github.com/IlianPihlajamaa/OrnsteinZernike.jl

RUN julia -e 'using Pkg; Pkg.add(PackageSpec(path="OrnsteinZernike.jl")); Pkg.instantiate()'
RUN julia -e 'using Pkg; Pkg.add("DelimitedFiles")'

COPY WCA.jl /workspace/WCA.jl
COPY entrypoint.sh /workspace/entrypoint.sh

RUN dos2unix /workspace/entrypoint.sh && chmod +x /workspace/entrypoint.sh

ENTRYPOINT ["bash", "/workspace/entrypoint.sh"]
