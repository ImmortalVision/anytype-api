[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Docker Pulls](https://img.shields.io/docker/pulls/immortalvision/anytype-api)](https://hub.docker.com/r/immortalvision/anytype-api)
[![Docker Image Size (tag)](https://img.shields.io/docker/image-size/immortalvision/anytype-api/latest)](https://hub.docker.com/r/immortalvision/anytype-api)

# anytype-api

Since anytype uses local-first approach for security and privacy,
their API only works on localhost, But if you want to create a bot
to interact with your channels, you need to expose the API so you can
access it from your bot.

Hence I've created this repo and published the image on
[Docker Hub](https://hub.docker.com/r/immortalvision/anytype-api) and
[GitHub Container Registry](https://github.com/orgs/ImmortalVision/packages/container/package/anytype-api).

## How this differs from the official `anyproto/anytype-api`

Despite the similar name, [anyproto/anytype-api](https://github.com/anyproto/anytype-api)
is not a server: it is the source of Anytype's developer portal
([developers.anytype.io](https://developers.anytype.io)), the docs and OpenAPI
specs. Its Dockerfile builds that website.

The API itself is part of Anytype's core, [anytype-heart](https://github.com/anyproto/anytype-heart),
and runs wherever that core runs: inside the desktop app (on `127.0.0.1:31009`,
only while the app is open) or inside the headless
[anytype-cli](https://github.com/anyproto/anytype-cli). This repo packages
**anytype-cli** as a container so the API can run on a server, next to your bots:

- a small image for `linux/amd64` and `linux/arm64`, on Docker Hub and ghcr
- works with the official sync network or a self-hosted
  [any-sync](https://github.com/anyproto/any-sync-tools) network (mount your `network.yml`)
- a sample [k8s deployment](deployments/k8s/deployment.yaml) with persistent storage

## Image tags

| Tag | anytype-cli | API |
| --- | --- | --- |
| `latest` | latest anytype-cli release | v1 |
| `apiv2`, `apiv2-<commit>` | built from source: [anyproto/anytype-cli#62](https://github.com/anyproto/anytype-cli/pull/62) (anytype-heart v0.51.3) | v1 + **v2** |

The `apiv2` image exists because no anytype-cli release ships the JSON API v2
yet. The Dockerfile builds anytype-cli from source at `ANYTYPE_CLI_REF`
(default: that pull request's commit); pass a release tag to build that instead:

```bash
docker build --build-arg ANYTYPE_CLI_REF=v0.3.7 -t your-org/anytype-api .
```

Once a release includes v2, `latest` will carry it too.

## API v2

v2 ([reference](https://developers.anytype.io/docs/reference/v2/anytype-api)) is
served next to v1 on the same port, under `/v2/`, and needs no `Anytype-Version`
header. Anytype marks it as a pre-release: it can change without a new API
version, so use v1 where you need a stable contract. Among other things, v2
returns an object's built-in cover and icon, filters with a compact grammar
(`{"filter": "published = true"}`), and serves an object as Markdown with
`?format=md`.

> [!IMPORTANT]
> **API keys changed.** With the `apiv2` image, keys are scoped to spaces and to
> read-only or read-write access, and `apikey create` requires both choices:
>
> ```bash
> anytype auth apikey create my-bot --space "My Space" --read-only   # v2 only
> anytype auth apikey create my-bot --all-spaces --read-write        # v1 and v2
> ```
>
> Keys limited to some spaces, or read-only, work with v2 only. Keys created by
> older versions keep working on v1 but are rejected by v2.

> [!IMPORTANT]
> **Allowed hosts.** The API only answers requests addressed to `localhost` or an
> IP. To reach it through a domain (a reverse proxy or ingress), allow that host:
> `-e ANYTYPE_API_ALLOWED_HOSTS=anytype-api.example.com` and
> `-e ANYTYPE_API_ALLOWED_ORIGINS=https://anytype-api.example.com`.

## Usage

If you want to use the official sync server, you can use the pre-built
image from Docker Hub or GHCR:

```bash
docker pull immortalvision/anytype-api:latest
# Or pull the same image from GHCR:
docker pull ghcr.io/immortalvision/anytype-api:latest
```

Run the image from Docker Hub:

> [!NOTE]
> If you want to deploy this repo on k8s, check our sample k8s deployment file
> [here](deployments/k8s/deployment.yaml).

```bash
docker run -d \
    -p 31012:31012 \
    --name anytype-api \
    -v ./data:/root/.anytype \
    -v ./storage:/config/data \
    immortalvision/anytype-api:latest
```

> [!WARNING]
> Mount **both** volumes. `/root/.anytype` holds the account key, but
> Anytype's own data (spaces, the device identity and **all API keys**) lives in
> `/config/data`. Without a volume there, a recreated container starts empty: it
> re-syncs everything from the network and every API key is gone.

To run the GHCR image instead, replace the image name in the command with
`ghcr.io/immortalvision/anytype-api:latest`. Both registries also provide
commit-specific tags.

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
    -v ./data:/root/.anytype \
    -v ./storage:/config/data \
    --name anytype-api \
    immortalvision/anytype-api:latest
```

That's it! Now you can access the API at `http://localhost:31012`.

## Changing the Port

If you want to change which port the API listens to, override the command
with the `--listen-address` flag like this:

```bash
docker run -d \
    -p 8888:80 \
    --name anytype-api \
    -v ./data:/root/.anytype \
    -v ./storage:/config/data \
    immortalvision/anytype-api:latest anytype serve --listen-address 0.0.0.0:80
```

## Next Steps

Now that you have the API up and running, you should initiate your bot
so it can start serving requests.

> [!WARNING]
> If you don't initiate your bot, the API will not serve any requests.

### Initiate Bot

To create a new bot run this:

> [!NOTE]
> If you're not running a self-hosted sync server,
> you can skip the `--network-config` flag.

```bash
anytype auth create my-bot --network-config ~/.config/anytype/network.yml
```

> [!WARNING]
> In my experience, after creating the bot, you should restart the container
> to make sure the bot is initiated properly.

Then you should join a channel:

```bash
anytype space join "<invite-link>"
```

To confirm that your bot has joined the channel, you can run this:

```bash
anytype space list
```

Now you can create an API key for the bot to access sync server
(with the `apiv2` image, choose spaces and access as shown in [API v2](#api-v2)):

```bash
anytype auth apikey create "<my-bot-api-key>"
```

This will create an api key that you can use to interact with sync-server,
the specs are [here](https://developers.anytype.io/docs/reference).
