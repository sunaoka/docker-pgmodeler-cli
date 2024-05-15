# syntax = docker/dockerfile:1.4
FROM --platform=$BUILDPLATFORM ubuntu:jammy-20240427 as base

ENV DEBIAN_FRONTEND=noninteractive

RUN <<EOT
    apt-get update
    apt-get upgrade -y
    apt-get install -y --no-install-recommends \
            libpq5 \
            libqt6network6 \
            libqt6printsupport6 \
            libqt6svg6 \
            libqt6widgets6 \
            qt6-qpa-plugins
EOT


FROM base as builder

ARG PGM_VERSION

ENV PGM_VERSION=$PGM_VERSION
ENV QT_SELECT=qt6

WORKDIR "/usr/local/src/pgmodeler"

RUN <<EOT
    apt-get install -y --no-install-recommends \
            build-essential \
            ca-certificates \
            libgl-dev \
            libpq-dev \
            libqt6svg6-dev \
            libxext-dev \
            libxml2-dev \
            pkg-config \
            qt6-base-dev \
            curl
EOT

RUN <<EOT
    ARCHITECTURE="$(uname -m)"

    printf "%s\n%s\n" "/usr/lib/qt6/bin" "/usr/lib/${ARCHITECTURE}-linux-gnu" > "/usr/share/qtchooser/qt6-${ARCHITECTURE}-linux-gnu.conf"
    ln -s "/usr/share/qtchooser/qt6-${ARCHITECTURE}-linux-gnu.conf" "/usr/lib/${ARCHITECTURE}-linux-gnu/qtchooser/qt6.conf"
EOT

RUN <<EOT
    curl -f -o "v${PGM_VERSION}.tar.gz" -LO "https://github.com/pgmodeler/pgmodeler/archive/v${PGM_VERSION}.tar.gz"
    tar -xzf "v${PGM_VERSION}.tar.gz"
EOT

WORKDIR "/usr/local/src/pgmodeler/pgmodeler-${PGM_VERSION}"

RUN <<EOT
    rm -f .qmake.stash
    qmake -r CONFIG+=release pgmodeler.pro
    make -j "$(nproc)"
    make install

    strip /usr/local/bin/pgmodeler-cli
    strip /usr/local/lib/pgmodeler/*
EOT

RUN <<EOT
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

RUN <<EOT
    mkdir -p /root/.config
    ln -s /usr/local/share/pgmodeler/conf /root/.config/pgmodeler-1.0

    apt-get install -y fonts-noto-cjk --no-install-recommends
    apt-get clean
    apt-get autoremove -y

    rm -rf /var/lib/apt/lists/*
    rm -rf /tmp/*

    mkdir -p /tmp/runtime-root
    chmod 0700 /tmp/runtime-root
EOT

WORKDIR /data

ENTRYPOINT ["/usr/local/bin/pgmodeler-cli"]
CMD []
