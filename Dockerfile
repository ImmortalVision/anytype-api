FROM golang:1.26-alpine AS build
LABEL maintainer='pezhvak <pezhvak@imvx.org>'
# anytype-cli is built from source so the image can carry an anytype-heart the
# released CLI doesn't ship yet. The default is anyproto/anytype-cli#62
# (anytype-heart v0.51.3: JSON API v2 + scoped API keys); pass a tag or commit
# of anytype-cli to build something else, e.g. --build-arg ANYTYPE_CLI_REF=v0.3.7
ARG ANYTYPE_CLI_REF=4de405e63f0a26cf030e4149df638b50ed4e5b65
RUN apk add --no-cache bash curl git make gcc g++ musl-dev
WORKDIR /src
RUN git init -q . \
 && git remote add origin https://github.com/anyproto/anytype-cli.git \
 && git fetch -q --depth 1 origin "$ANYTYPE_CLI_REF" \
 && git checkout -q FETCH_HEAD
# static musl binary, same flags as the upstream linux release builds
RUN make build \
      BUILD_TAGS=noheic \
      VERSION="$(echo "$ANYTYPE_CLI_REF" | cut -c1-12)" \
      EXTRA_LDFLAGS="-linkmode external -extldflags '-static'" \
      OUTPUT=/out/anytype

FROM alpine:latest
LABEL org.opencontainers.image.source="https://github.com/ImmortalVision/anytype-api"
RUN apk add --no-cache ca-certificates
RUN mkdir /bot
WORKDIR /bot
COPY --from=build /out/anytype /usr/bin
RUN anytype --version
# Mount your network.yml into this folder
RUN mkdir /config
RUN mkdir /root/.config
RUN ln -s /config ~/.config/anytype
# gRPC
EXPOSE 31010
# gRPC-Web
EXPOSE 31011
# HTTP API
EXPOSE 31012

CMD ["anytype", "serve"]
