FROM ubuntu:focal as base

ARG DEBIAN_FRONTEND=noninteractive

RUN apt update \
 && apt upgrade -y \
 && apt install -y \
        libpq5 \
        qt5-default


FROM base as builder

ENV PGM_VERSION "0.9.3"

WORKDIR "/usr/local/src/pgmodeler"

ARG DEBIAN_FRONTEND=noninteractive

RUN apt install -y \
        build-essential \
        libpq-dev \
        libqt5svg5-dev \
        libxml2-dev \
        pkg-config \
        qt5-qmake \
        wget

RUN mkdir -p /usr/local/src/pgmodeler

RUN wget https://github.com/pgmodeler/pgmodeler/archive/v$PGM_VERSION.tar.gz \
  && tar -xzvf v$PGM_VERSION.tar.gz

WORKDIR "/usr/local/src/pgmodeler/pgmodeler-$PGM_VERSION"

RUN qmake pgmodeler.pro && \
    make -j $(nproc) && \
    make install

WORKDIR "/usr/local/lib"

RUN tar cvf /tmp/pgmodeler-lib.tar pgmodeler

WORKDIR "/usr/local/share"

RUN tar cvf /tmp/pgmodeler-share.tar pgmodeler


FROM base

COPY --from=builder /tmp/pgmodeler-lib.tar /tmp/
COPY --from=builder /tmp/pgmodeler-share.tar /tmp/
COPY --from=builder /usr/local/bin/pgmodeler-cli /usr/local/bin/
COPY config/ /root/.config/pgmodeler/

ARG DEBIAN_FRONTEND=noninteractive

RUN apt clean \
 && apt autoremove -y \
 && tar xvf /tmp/pgmodeler-lib.tar -C /usr/local/lib \
 && tar xvf /tmp/pgmodeler-share.tar -C /usr/local/share \
 && rm -rf /var/lib/apt/lists/* \
 && rm -rf /tmp/* \
 && mkdir -p /tmp/runtime-root \
 && chmod 0700 /tmp/runtime-root

ENV QT_QPA_PLATFORM=offscreen
ENV XDG_RUNTIME_DIR=/tmp/runtime-root

WORKDIR /data

ENTRYPOINT ["/usr/local/bin/pgmodeler-cli"]
CMD []
