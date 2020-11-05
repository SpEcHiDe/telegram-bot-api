#  creates a layer from the base Docker image.
FROM alpine:latest AS builder

# Dockerfile stolen from
# https://hub.docker.com/r/julyighor/telegram-bot-api
RUN apk --no-cache add --update \
    alpine-sdk \
    linux-headers \
    git \
    zlib-dev \
    openssl-dev \
    gperf \
    cmake && \
    git clone --recursive https://github.com/tdlib/telegram-bot-api.git && \
    cd telegram-bot-api && \
    mkdir build && \
    cd build && \
    export CXXFLAGS="" && \
    export MAKEFLAGS="-j 2" && \
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX:PATH=.. .. && \
    cmake --build . --target install && \
    strip /telegram-bot-api/bin/telegram-bot-api

FROM alpine:latest

WORKDIR /app

RUN apk --no-cache add --update openssl libstdc++

COPY --from=builder /telegram-bot-api/bin/telegram-bot-api /usr/bin/telegram-bot-api
# each instruction creates one layer
# Only the instructions RUN, COPY, ADD create layers.
# copies 'requirements', to inside the container
# ..., there are multiple '' dependancies,
# requiring the use of the entire repo, hence
# adds files from your Docker client’s current directory.
COPY . .

RUN chmod a+x docker-entrypoint.sh

ENTRYPOINT ["./docker-entrypoint.sh"]
