---
title: "docker memo"
date: 2024-3-6T09:00:00
#image: "images/team/nonsap-visuals-kMJp7620W6U-unsplash.jpg"
jobtitle: "memo"
linkedinurl: ""
weight: 7
---

## container のnetworkを付け替える

```bash
~/Documents$ docker network list
NETWORK ID     NAME                         DRIVER    SCOPE
22e80fdb6bd5   bridge                       bridge    local
aa48eab8a619   docker_default               bridge    local
d382e7d1efba   host                         host      local
aa45d45e8477   jekyll-serif-theme_default   bridge    local
3971de1d3274   m1-v14-0-0_default           bridge    local
dc4d8327e1a6   mysql_default                bridge    local
c95ac591d076   none                         null      local
300b00f5c712   redis-express-api_default    bridge    local
c65fd42c8f3f   redius_default               bridge    local
70f11271250f   workday_default              bridge    local
```

```bash
~/Documents$ docker ps -a
CONTAINER ID   IMAGE                                                         COMMAND                   CREATED             STATUS                         PORTS     NAMES
4b4d414c2e83   e28c06052087                                                  "docker-entrypoint.s…"   About an hour ago   Exited (1) About an hour ago             objective_mirzakhani
8d03455a6d93   mcr.microsoft.com/devcontainers/typescript-node:20-bullseye   "/bin/sh -c 'echo Co…"   5 weeks ago         Exited (0) 5 weeks ago                   hardcore_mcnulty
d294ebf32479   1214e5db6574                                                  "docker-entrypoint.s…"   2 months ago        Exited (137) 2 months ago                workday-app-1
809fd9e58002   470ffd1da2b0                                                  "redis-stack-server …"   2 months ago        Exited (137) 2 months ago                workday-redis-1
c97910f56bad   470ffd1da2b0                                                  "redis-stack-server …"   3 months ago        Exited (137) 4 weeks ago                 redis-stack-server
a7a6b0f31508   jboss/keycloak:14.0.0                                         "/opt/jboss/tools/do…"   3 months ago        Exited (0) 3 minutes ago                 keycloak
aa0f606e1473   jekyll-serif-theme-jekyll                                     "/usr/jekyll/bin/ent…"   4 months ago        Exited (137) 9 hours ago                 jekyll-serif-theme-jekyll-1
a1b3ec38ca72   redis:latest                                                  "docker-entrypoint.s…"   4 months ago        Exited (0) 3 minutes ago                 redius-redis-1
0b8459b69ac1   mysql:8.0.33                                                  "docker-entrypoint.s…"   4 months ago        Exited (0) 3 minutes ago                 mysql_host
04eccbd05a37   quay.io/keycloak/keycloak:22.0.4                              "/opt/keycloak/bin/k…"   5 months ago        Exited (143) 3 months ago                determined_jemison
```

```bash
# 今接続しているnetworkを表示
docker inspect --format='{{.Name}} - {{range $key, $_ := .NetworkSettings.Networks}}{{$key}}{{"\n"}}{{end}}' redius-redis-1

# コンテナを現在のネットワークから切断する:
docker network disconnect redius_default redius-redis-1

# コンテナを新しいネットワークに接続する:
docker network connect mysql_default redius-redis-1
```

# docker rmi

```bash
# noneのimageを削除
docker rmi $(docker images -f "dangling=true" -q)


```

# docker compose

```bash
# コンテナとネットワークの削除:
docker compose down
# ボリュームの削除:
docker compose down -v
```
