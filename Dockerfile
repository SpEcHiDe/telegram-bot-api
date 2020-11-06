# creates a layer from the base Docker image.
FROM alpine:3.7 AS builder

RUN apk update && \
  apk upgrade

RUN apk add --update \
    alpine-sdk \
    linux-headers \
    git \
    zlib-dev \
    openssl-dev \
    gperf \
    php7 \
    php7-ctype \
    cmake && \
  php --version && \
  git clone --recursive https://github.com/tdlib/telegram-bot-api.git && \
  cd telegram-bot-api && \
  rm -rf build && \
  mkdir build && \
  cd build && \
  export CXXFLAGS="" && \
  cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX:PATH=.. .. && \
  cmake --build . --target prepare_cross_compiling && \
  cd ../td && \
  php SplitSource.php && \
  cd ../build && \
  cmake --build . --target install && \
  cd ../td && \
  php7 SplitSource.php --undo && \
  cd ../.. && \
  ls -l /telegram-bot-api/bin/telegram-bot-api*


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
