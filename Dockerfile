FROM --platform=$BUILDPLATFORM ubuntu:jammy-20240212 as base

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get upgrade -y \
 && apt-get install -y --no-install-recommends \
            libpq5 \
            libqt6network6 \
            libqt6printsupport6 \
            libqt6svg6 \
            libqt6widgets6 \
            qt6-qpa-plugins


FROM base as builder

ARG PGM_VERSION

ENV PGM_VERSION $PGM_VERSION

ENV QT_SELECT qt6

WORKDIR "/usr/local/src/pgmodeler"

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get install -y --no-install-recommends \
            build-essential \
            ca-certificates \
            libgl-dev \
            libpq-dev \
            libqt6svg6-dev \
            libxext-dev \
            libxml2-dev \
            pkg-config \
            qt6-base-dev \
            wget

RUN ARCHITECTURE="$(uname -m)" \
 && export ARCHITECTURE \
 && printf "%s\n%s\n" "/usr/lib/qt6/bin" "/usr/lib/${ARCHITECTURE}-linux-gnu" > "/usr/share/qtchooser/qt6-${ARCHITECTURE}-linux-gnu.conf" \
 && ln -s "/usr/share/qtchooser/qt6-${ARCHITECTURE}-linux-gnu.conf" "/usr/lib/${ARCHITECTURE}-linux-gnu/qtchooser/qt6.conf"

RUN mkdir -p /usr/local/src/pgmodeler

RUN wget -q "https://github.com/pgmodeler/pgmodeler/archive/v${PGM_VERSION}.tar.gz" \
 && tar -xzvf "v${PGM_VERSION}.tar.gz"

WORKDIR "/usr/local/src/pgmodeler/pgmodeler-${PGM_VERSION}"

RUN rm -f .qmake.stash \
 && qmake -r CONFIG+=release pgmodeler.pro \
 && make -j "$(nproc)" \
 && make install \
 && strip /usr/local/bin/pgmodeler-cli \
 && strip /usr/local/lib/pgmodeler/*

WORKDIR "/usr/local/lib"

RUN tar cvf /tmp/pgmodeler-lib.tar pgmodeler

WORKDIR "/usr/local/share"

RUN tar cvf /tmp/pgmodeler-share.tar pgmodeler


FROM base

COPY --from=builder /tmp/pgmodeler-lib.tar /tmp/
COPY --from=builder /tmp/pgmodeler-share.tar /tmp/
COPY --from=builder /usr/local/bin/pgmodeler-cli /usr/local/bin/

ARG DEBIAN_FRONTEND=noninteractive

RUN tar xvf /tmp/pgmodeler-lib.tar -C /usr/local/lib \
 && tar xvf /tmp/pgmodeler-share.tar -C /usr/local/share \
 && mkdir -p /root/.config \
 && ln -s /usr/local/share/pgmodeler/conf /root/.config/pgmodeler-1.0 \
 && apt-get install -y fonts-noto-cjk --no-install-recommends \
 && apt-get clean \
 && apt-get autoremove -y \
 && rm -rf /var/lib/apt/lists/* \
 && rm -rf /tmp/* \
 && mkdir -p /tmp/runtime-root \
 && chmod 0700 /tmp/runtime-root

ENV QT_QPA_PLATFORM=offscreen
ENV XDG_RUNTIME_DIR=/tmp/runtime-root

WORKDIR /data

ENTRYPOINT ["/usr/local/bin/pgmodeler-cli"]
CMD []
