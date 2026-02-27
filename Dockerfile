FROM golang:alpine AS build
MAINTAINER 'pezhvak <pezhvak@imvx.org>'
WORKDIR /root
RUN apk add bash curl
RUN curl https://raw.githubusercontent.com/anyproto/anytype-cli/refs/heads/main/install.sh > install.sh
RUN chmod +x install.sh
RUN bash /root/install.sh

FROM alpine:latest
RUN mkdir /bot
WORKDIR /bot
COPY --from=build /root/.local/bin/anytype /usr/bin
RUN anytype --version
# Mount your network.yml into this folder
RUN mkdir /config
RUN mkdir /root/.config
RUN ln -s /config ~/.config/anytype
RUN echo "anytype serve" > entrypoint.sh
RUN chmod +x entrypoint.sh
# gRPC
EXPOSE 31010
# gRPC-Web
EXPOSE 31011
# HTTP API
EXPOSE 31012

CMD ["ash", "/bot/entrypoint.sh"]
