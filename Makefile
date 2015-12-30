# Container parameters
NAME = wackyvik/confluence
VERSION = $(shell /bin/cat CONFLUENCE.VERSION)
JAVA_OPTS = -Djava.io.tmpdir=/var/tmp -XX:-UseAESIntrinsics -Dcom.sun.net.ssl.checkRevocation=false
MEMORY_LIMIT = 8192
CONFIGURE_SQL_DATASOURCE = FALSE
CONFIGURE_FRONTEND = FALSE
CONFLUENCE_DB_DRIVER = org.postgresql.Driver
CONFLUENCE_DB_URL = jdbc:postgresql://docker0:5432/confluence?useUnicode=true&amp;characterEncoding=utf8
CONFLUENCE_DB_USER = confluence
CONFLUENCE_DB_PASSWORD = confluence
CONFLUENCE_FE_NAME = confluence.local
CONFLUENCE_FE_PORT = 443
CONFLUENCE_FE_PROTO = https
CPU_LIMIT_CPUS = 0-2
CPU_LIMIT_LOAD = 100
IO_LIMIT = 500

# Calculated parameters.
VOLUMES_FROM = $(shell if [ $$(/usr/bin/docker ps -a | /bin/grep -i "$(NAME)" | /bin/wc -l) -gt 0 ]; then /bin/echo -en "--volumes-from="$$(/usr/bin/docker ps -a | /bin/grep -i "$(NAME)" | /bin/tail -n 1 | /usr/bin/awk "{print \$$1}"); fi)
SWAP_LIMIT = $(shell /bin/echo $$[$(MEMORY_LIMIT)*2])
JAVA_MEM_MAX = $(shell /bin/echo $$[$(MEMORY_LIMIT)-32+$(SWAP_LIMIT)])m
JAVA_MEM_MIN = $(shell /bin/echo $$[$(MEMORY_LIMIT)/4])m
CPU_LIMIT_LOAD_THP = $(shell /bin/echo $$[$(CPU_LIMIT_LOAD)*1000])

.PHONY: all build install

all: build install

build:
	/usr/bin/docker build -t $(NAME):$(VERSION) --rm image

install:
	/usr/bin/docker run --publish 8091:8090 --name=confluence-$(VERSION) $(VOLUMES_FROM)                      \
						-e CONFIGURE_SQL_DATASOURCE="$(CONFIGURE_SQL_DATASOURCE)"         \
						-e CONFIGURE_FRONTEND="$(CONFIGURE_FRONTEND)"                     \
						-e JAVA_OPTS="$(JAVA_OPTS)"                                       \
						-e JAVA_MEM_MAX="$(JAVA_MEM_MAX)"                                 \
						-e JAVA_MEM_MIN="$(JAVA_MEM_MIN)"                                 \
						-e CONFLUENCE_DB_DRIVER="$(CONFLUENCE_DB_DRIVER)"                 \
						-e CONFLUENCE_DB_URL="$(CONFLUENCE_DB_URL)"                       \
						-e CONFLUENCE_DB_USER="$(CONFLUENCE_DB_USER)"                     \
						-e CONFLUENCE_DB_PASSWORD="$(CONFLUENCE_DB_PASSWORD)"             \
						-e CONFLUENCE_FE_NAME="$(CONFLUENCE_FE_NAME)"                     \
						-e CONFLUENCE_FE_PORT="$(CONFLUENCE_FE_PORT)"                     \
						-e CONFLUENCE_FE_PROTO="$(CONFLUENCE_FE_PROTO)"                   \
						-m $(MEMORY_LIMIT)M --memory-swap $(JAVA_MEM_MAX)                 \
						--oom-kill-disable=false                                          \
						--cpuset-cpus=$(CPU_LIMIT_CPUS) --cpu-quota=$(CPU_LIMIT_LOAD_THP) \
						--blkio-weight=$(IO_LIMIT)                                        \
						-d wackyvik/confluence:$(VERSION)
