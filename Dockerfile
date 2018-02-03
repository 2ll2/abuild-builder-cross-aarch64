FROM 2ll2/repo-sdk:v3.7-90eac9a-aarch64.x86_64 AS repo-sdk

FROM alpine:3.7 AS alpine

COPY --from=repo-sdk /home/builder/repo/sdk/ /tmp/docker-build/repo-sdk/

COPY [ \
  "./docker-extras/*", \
  "/tmp/docker-build/" \
]

RUN \
  # apk
  apk update && \
  apk add \
    alpine-baselayout \
    alpine-sdk \
    vim && \
  \
  mkdir -p /var/cache/distfiles && \
  adduser -D -u 500 builder && \
  addgroup builder abuild && \
  chgrp abuild /var/cache/distfiles && \
  chmod g+w /var/cache/distfiles && \
  echo "builder    ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
  su -l builder -c "git config --global user.email Builder" && \
  su -l builder -c "git config --global user.name builder@lambda2" && \
  \
  sed -i -e "/^#PACKAGER.*$/d" /etc/abuild.conf && \
  echo 'PACKAGER="Builder <builder@lambda2>"' >> /etc/abuild.conf && \
  \
  # Enable this when generating new keys
  # su -l builder -c "abuild-keygen -a -n" && \
  su -l builder -c "mkdir .abuild" && \
  su -l builder -c "cp /tmp/docker-build/home-builder-.abuild-abuild.conf .abuild/abuild.conf" && \
  su -l builder -c "cp /tmp/docker-build/home-builder-.abuild-Builder-59ffc9b9.rsa .abuild/Builder-59ffc9b9.rsa" && \
  su -l builder -c "cp /tmp/docker-build/home-builder-.abuild-Builder-59ffc9b9.rsa.pub .abuild/Builder-59ffc9b9.rsa.pub" && \
  su -l builder -c "chmod 640 .abuild/Builder-59ffc9b9.rsa" && \
  cp /home/builder/.abuild/*.rsa.pub /etc/apk/keys && \
  \
  # setup cross-build tools and sysroot-aarch64
  echo "@repo-sdk /tmp/docker-build/repo-sdk/v3.7/main" >> /etc/apk/repositories && \
  apk update && \
  apk add build-base-aarch64@repo-sdk && \
  su -l builder -c "mkdir -p /home/builder/sysroot-aarch64/etc/apk/keys" && \
  su -l builder -c "cp -a /etc/apk/keys/* /home/builder/sysroot-aarch64/etc/apk/keys" && \
  su -l builder -c "cp -a /usr/share/apk/keys/*.rsa.pub /home/builder/sysroot-aarch64/etc/apk/keys" && \
  su -l builder -c "abuild-apk add --root /home/builder/sysroot-aarch64 --initdb --arch aarch64" && \
  # following is adapted from bootstrap.sh script. In the cross-build toolchain,
  # we only ship aarch64 libgcc, libstdc++, musl. The rest is pulled from
  # upstream aarch64 repository as required using a patched abuild. abuild-apk
  # update downloads and caches APKINDEX. abuild is also patched to pull
  # packages from upstream aarch64 repository
  su -l builder -c "abuild-apk add --root /home/builder/sysroot-aarch64 --arch aarch64 --repository /tmp/docker-build/repo-sdk/v3.7/main --no-scripts libgcc libstdc++ musl-dev" && \
  su -l builder -c "abuild-apk update --root /home/builder/sysroot-aarch64/ --arch aarch64 --repository http://dl-cdn.alpinelinux.org/alpine/v3.7/main" && \
  su -l builder -c "abuild-apk add --root /home/builder/sysroot-aarch64 --arch aarch64 --repository http://dl-cdn.alpinelinux.org/alpine/v3.7/main --no-scripts build-base" && \
  \
  # patch abuild
  cd /usr/bin && \
  patch -p1 < /tmp/docker-build/abuild-add-alpine-v3-7-main.patch && \
  \
  # remove @repo-sdk from apk
  sed -i -e 's/@repo-sdk//' /etc/apk/world && \
  sed -i -e '/@repo-sdk/d' /etc/apk/repositories && \
  \
  # cleanup
  cd /root && \
  rm -rf /tmp/* && \
  rm -f /var/cache/apk/*
