# syntax = docker/dockerfile:1
# check=error=true
FROM ubuntu:resolute-20261024.1 AS base

RUN <<'EOT' sh -ex
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get upgrade -y
    apt-get install -y --no-install-recommends \
            libpq5 \
            libqt6network6 \
            libqt6printsupport6 \
            libqt6svg6 \
            libqt6widgets6 \
            qt6-qpa-plugins
    rm -rf /var/lib/apt/lists/*
EOT


FROM base AS builder

ARG PGM_VERSION

WORKDIR "/usr/local/src/pgmodeler"

RUN <<'EOT' sh -ex
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get install -y --no-install-recommends \
            build-essential \
            ca-certificates \
            clang \
            cmake \
            libpq-dev \
            libqt6svg6-dev \
            libxml2-dev \
            pkg-config \
            qt6-base-dev \
            qt6-tools-dev \
            curl
    rm -rf /var/lib/apt/lists/*
EOT

RUN <<'EOT' sh -ex
    curl -fL -o "v${PGM_VERSION}.tar.gz" "https://github.com/nullptrlabs/pgmodeler/archive/refs/tags/v${PGM_VERSION}.tar.gz"
    tar -xzf "v${PGM_VERSION}.tar.gz"
EOT

WORKDIR "/usr/local/src/pgmodeler/pgmodeler-${PGM_VERSION}"

RUN <<'EOT' sh -ex
    cmake -S . -B build \
        -DCMAKE_BUILD_TYPE=Release \
        -DPGM_PREFIX=/usr/local \
        -DPGM_CONFDIR=/usr/local/share/pgmodeler/conf \
        -DPGM_LANGDIR=/usr/local/share/pgmodeler/lang \
        -DPGM_SAMPLESDIR=/usr/local/share/pgmodeler/samples \
        -DPGM_SCHEMASDIR=/usr/local/share/pgmodeler/schemas
    cmake --build build --parallel 2
    cmake --install build

    strip /usr/local/bin/pgmodeler-cli
    strip /usr/local/lib/pgmodeler/*
EOT

RUN <<'EOT' sh -ex
    mkdir -p /tmp/local/bin
    mkdir -p /tmp/local/lib
    mkdir -p /tmp/local/share
    cp -pR /usr/local/bin/pgmodeler-cli /tmp/local/bin
    cp -pR /usr/local/lib/pgmodeler /tmp/local/lib
    cp -pR /usr/local/share/pgmodeler /tmp/local/share
EOT


FROM base

COPY --link --from=builder /tmp/local/ /usr/local/

ENV QT_QPA_PLATFORM=offscreen
ENV XDG_RUNTIME_DIR=/tmp/runtime-root
ENV LANG=C.UTF-8

RUN <<'EOT' sh -ex
    mkdir -p /root/.config
    ln -s /usr/local/share/pgmodeler/conf /root/.config/pgmodeler-2.0

    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get install -y fonts-noto-cjk --no-install-recommends
    apt-get clean

    rm -rf /var/lib/apt/lists/*

    mkdir -p /tmp/runtime-root
    chmod 0700 /tmp/runtime-root
EOT

WORKDIR /data

ENTRYPOINT ["/usr/local/bin/pgmodeler-cli"]

CMD []
