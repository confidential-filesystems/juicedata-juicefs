FROM golang:1.21.7 AS builder

ARG WEBDAV_TAG=main

RUN mkdir -p -m 0600 ~/.ssh && \
    ssh-keyscan -H github.com >> ~/.ssh/known_hosts
RUN cat <<EOF > ~/.gitconfig
[url "ssh://git@github.com/"]
    insteadOf = https://github.com/
EOF

WORKDIR /usr/src
COPY . juicedata-juicefs
RUN --mount=type=ssh cd juicedata-juicefs && go mod download && \
    set -eux; \
    REVISION=$(git rev-parse --short HEAD 2>/dev/null); \
    REVISIONDATE=$(git log -1 --pretty=format:'%cd' --date short 2>/dev/null); \
    PKG=github.com/juicedata/juicefs/pkg/version; \
    LDFLAGS="-s -w -X ${PKG}.revision=${REVISION} -X ${PKG}.revisionDate=${REVISIONDATE}"; \
    GOOS=linux GOARCH=amd64 CGO_LDFLAGS="-static" go build -tags nogateway,nowebdav,nocos,nobos,nohdfs,noibmcos,noobs,nooss,noqingstor,noscs,nosftp,noswift,noupyun,noazure,nogs,noufile,nob2,nosqlite,nomysql,nopg,notikv,nobadger,noetcd \
    -ldflags="${LDFLAGS}" -o juicefs .

RUN --mount=type=ssh git clone --depth 1 --branch ${WEBDAV_TAG} git@github.com:confidential-filesystems/filesystem-webdav.git && \
    cd filesystem-webdav && go mod download && \
    set -eux; \
    REVISION=$(git rev-parse --short HEAD 2>/dev/null); \
    LDFLAGS="-X 'github.com/confidential-filesystems/filesystem-webdav/cmd.version=${REVISION}'"; \
    CGO_ENABLED=0 GOOS=linux GOARCH=amd64 CGO_LDFLAGS="-static" go build -ldflags "${LDFLAGS}" -o filesystem-webdav

FROM confidentialfilesystems/sidecar:v1.0.0-amd64

COPY --from=builder /usr/src/juicedata-juicefs/juicefs /usr/local/bin/juicefs
COPY --from=builder /usr/src/filesystem-webdav/filesystem-webdav  /usr/local/bin/filesystem-webdav
COPY --from=builder /usr/src/filesystem-webdav/examples/config-example.yaml /etc/webdav/config.yaml
COPY scripts /usr/local/bin/

RUN ln -s /usr/local/bin/juicefs /bin/mount.juicefs
RUN /usr/local/bin/juicefs version