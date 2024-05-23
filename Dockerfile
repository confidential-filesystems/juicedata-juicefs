#FROM juicedata/mount:nightly
FROM juicedata/mount:ce-v1.1.2
COPY ./juicefs /usr/local/bin/juicefs
# RUN apt-get update && apt-get install -y musl-tools upx-ucl && STATIC=1 make
# RUN cp -f juicefs /usr/local/bin/juicefs
# RUN ln -s /usr/local/bin/juicefs /bin/mount.juicefs
RUN /usr/local/bin/juicefs version