# abuild aarch64 cross builder for v3.7

This docker image has `abuild` setup to cross build aarch64 `.apk` packages.

To get started

```
$ cd abuild-builder-cross-aarch64/

$ docker build --squash -t abuild-builder-cross-aarch64 .
```

Go to the _parent_ directory containing `aports` tree.

```
$ docker run --rm -ti -v $(pwd):/home/builder/src \
     -v <PATH_TO_REPO_BASE_ON_HOST>:/home/builder/repo/<REPO_BASE> \
     abuild-builder-cross-aarch64 /bin/su -l -s /bin/sh builder

(For example)

$ docker run --rm -ti -v $(pwd):/home/builder/src \
  -v /home/ll-user/work/lambda2/repo/aarch64-domU/v3.7:/home/builder/repo/aarch64-domU/v3.7 \
  abuild-builder-cross-aarch64 /bin/su -l -s /bin/sh builder

f5c1eee20ebe:~$ sudo apk update

f5c1eee20ebe:~$ cd src/aports-aarch64-domU/main/busybox/

f5c1eee20ebe:~/src/aports-aarch64-domU/main/busybox$ CHOST=aarch64 abuild \
  -c -r -P /home/builder/repo/aarch64-domU/v3.7

f5c1eee20ebe:~/src/aports-aarch64-domU/main/busybox$ CHOST=aarch64 abuild \
  -P /home/builder/repo/aarch64-domU/v3.7 cleanoldpkg
```
