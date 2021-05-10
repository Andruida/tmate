ARG PLATFORM=amd64
FROM ${PLATFORM}/alpine:3.10 AS build

WORKDIR /build

RUN apk add --no-cache wget cmake make gcc g++ linux-headers zlib-dev openssl-dev \
            automake autoconf libevent-dev ncurses-dev msgpack-c-dev libexecinfo-dev \
            ncurses-static libexecinfo-static libevent-static msgpack-c ncurses-libs \
            libevent libexecinfo openssl zlib

RUN set -ex; \
            mkdir -p /src/libssh/build; \
            cd /src; \
            wget -O libssh.tar.xz https://www.libssh.org/files/0.9/libssh-0.9.0.tar.xz; \
            tar -xf libssh.tar.xz -C /src/libssh --strip-components=1; \
            cd /src/libssh/build; \
            cmake -DCMAKE_INSTALL_PREFIX:PATH=/usr \
            -DWITH_SFTP=OFF -DWITH_SERVER=OFF -DWITH_PCAP=OFF \
            -DWITH_STATIC_LIB=ON -DWITH_GSSAPI=OFF ..; \
            make -j $(nproc); \
            make install

COPY compat ./compat
COPY *.c *.h autogen.sh Makefile.am configure.ac ./

RUN ./autogen.sh && ./configure --enable-static
RUN make -j $(nproc)
RUN objcopy --only-keep-debug tmate tmate.symbols && chmod -x tmate.symbols && strip tmate
RUN ./tmate -V

FROM ubuntu

ARG DEBIAN_FRONTEND=noninteractive

RUN sed -i 's:^path-exclude=/usr/share/man:#path-exclude=/usr/share/man:' /etc/dpkg/dpkg.cfg.d/excludes
RUN mkdir /build
ENV PATH=/build:$PATH
COPY --from=build /build/tmate.symbols /build
COPY --from=build /build/tmate /build

RUN apt-get update && apt-get install -y apg sudo locales tzdata apt-utils man manpages-posix less \
 && rm -rf /var/lib/apt/lists/* \
 && localedef -i hu_HU -c -f UTF-8 -A /usr/share/locale/locale.alias hu_HU.UTF-8 \
 && echo "root:`apg -n1`" | chpasswd 
# && useradd -m -p sKzEqcFhB5Zfo -s /bin/bash admin \
# && usermod -aG sudo admin


ENV LANG hu_HU.utf8
ENV TZ=Europe/Budapest

COPY entrypoint.sh ./
RUN chmod a+x entrypoint.sh

ENTRYPOINT ["bash", "./entrypoint.sh"]
