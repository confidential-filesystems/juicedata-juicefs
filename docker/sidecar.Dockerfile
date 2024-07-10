FROM ubuntu:20.04 as builder
RUN apt-get update && \
    apt-get install -y --no-install-recommends cryptsetup-bin e2fsprogs && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

COPY ./juicefs /usr/local/bin/juicefs
COPY ./filesystem-webdav /usr/local/bin/filesystem-webdav
COPY ./webdav-config.yaml /etc/webdav/config.yaml
COPY ./open_block_device.sh /usr/local/bin/open_block_device.sh
COPY ./close_block_device.sh /usr/local/bin/close_block_device.sh
RUN ln -s /usr/local/bin/juicefs /bin/mount.juicefs
RUN /usr/local/bin/juicefs version

#FROM gcr.io/distroless/static-debian11:debug
#COPY --from=builder /usr/local/bin/juicefs /usr/local/bin/juicefs
#COPY --from=builder /sbin/cryptsetup /sbin/cryptsetup
#COPY --from=builder /sbin/mkfs.ext4 /sbin/mkfs.ext4
#COPY --from=builder /sbin/e2fsck /sbin/e2fsck
#COPY --from=builder /usr/sbin/resize2fs /usr/sbin/resize2fs
#
#COPY --from=builder /lib/x86_64-linux-gnu/libdevmapper.so.1.02.1 /lib/x86_64-linux-gnu/
#COPY --from=builder /usr/lib/x86_64-linux-gnu/libargon2.so.* /usr/lib/x86_64-linux-gnu/
#COPY --from=builder /usr/lib/x86_64-linux-gnu/*.so.* /usr/lib/x86_64-linux-gnu/

#RUN ln -s /usr/local/bin/juicefs /bin/mount.juicefs