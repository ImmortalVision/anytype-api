[![Docker Pulls](https://img.shields.io/docker/pulls/immortalvision/anytype-api)](https://hub.docker.com/r/immortalvision/anytype-api)
[![Docker Image Size (tag)](https://img.shields.io/docker/image-size/immortalvision/anytype-api/latest)](https://hub.docker.com/r/immortalvision/anytype-api)

# anytype-api

Since anytype uses local-first approach for security and privacy,
their API only works on localhost, But if you wan to create a bot
to interact with your channels, you need to expose the API so you can
access it from your bot.

Hence I've created this repo (and a docker image on dockerhub).

## Usage

If you want to use the official sync server, you can just get the pre-built
image from dockerhub and use it like this:

```bash
docker run -d \
    -p 31012:31012 \
    --name anytype-api \
    immortalvision/anytype-api:latest
```

But if you're running self-hosted sync server, or you want to build the image yourself,
you can clone this repo and build the image like this:

```bash
git clone https://github.com/ImmortalVision/anytype-api.git
cd anytype-api
# you might want to bake in the network.yml
# to do this you can modify Dockerfile.
docker build -t your-org/anytype-api:latest .
```

After building the image, you should mount your `network.yml` created
by [any-sync server](https://github.com/anyproto/any-sync-tools), into the
container and run it like this:

```bash
docker run -d \
    -p 31012:31012 \
    -v /path/to/your/anytype/network.yml:/config/network.yml \
    --name anytype-api \
    immortalvision/anytype-api:latest
```

That's it! Now you can access the API at `http://localhost:31012`.

```ad-note
if you want to change which port the API listens to,
you can change the `--listen-address` flag in the `Dockerfile` like this:
docker run -d \
    -p 8888:80 \
    --name anytype-api \
    immortalvision/anytype-api:latest --listen-address 0.0.0.0:80
```
