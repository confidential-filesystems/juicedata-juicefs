FROM golang:1.21.7 AS juicefs_builder

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

FROM confidentialfilesystems/filesystem-webdav:v0.1.0 AS webdav_builder

FROM confidentialfilesystems/sidecar:v1.0.0-amd64

COPY --from=juicefs_builder /usr/src/juicedata-juicefs/juicefs /usr/local/bin/juicefs
COPY --from=webdav_builder /usr/local/bin/filesystem-webdav  /usr/local/bin/filesystem-webdav
COPY --from=webdav_builder /etc/webdav/config.yaml /etc/webdav/config.yaml
COPY scripts/open_block_device.sh /usr/local/bin/open_block_device.sh
COPY scripts/close_block_device.sh /usr/local/bin/close_block_device.sh
RUN ln -s /usr/local/bin/juicefs /bin/mount.juicefs
RUN /usr/local/bin/juicefs version