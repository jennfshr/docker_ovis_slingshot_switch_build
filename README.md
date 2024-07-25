This is a rather simple implementation of a docker build and run invocation on a Macintosh Apple M2 Max.

No positional parameters are supplied to the script, but it will prompt for a docker username and password to authenticate to the docker registry.

The successful execution of the script will output the following execution trace of the docker build steps and a print statement directing the user to the resulting tarball on their desktop.

```sh
jkgreen@s1105469 ldms_docker % ./run_ldms_docker.sh
Enter Docker Hub Username:
Enter Docker Hub Password:
Login Succeeded
[+] Building 55.9s (8/8) FINISHED                                                                                                               docker:desktop-linux
 => [internal] load build definition from Dockerfile                                                                                                            0.0s
 => => transferring dockerfile: 1.48kB                                                                                                                          0.0s
 => [internal] load metadata for docker.io/library/debian:buster                                                                                                0.7s
 => [auth] library/debian:pull token for registry-1.docker.io                                                                                                   0.0s
 => [internal] load .dockerignore                                                                                                                               0.0s
 => => transferring context: 2B                                                                                                                                 0.0s
 => [1/3] FROM docker.io/library/debian:buster@sha256:58ce6f1271ae1c8a2006ff7d3e54e9874d839f573d8009c20154ad0f2fb0a225                                          0.0s
 => => resolve docker.io/library/debian:buster@sha256:58ce6f1271ae1c8a2006ff7d3e54e9874d839f573d8009c20154ad0f2fb0a225                                          0.0s
 => => sha256:58ce6f1271ae1c8a2006ff7d3e54e9874d839f573d8009c20154ad0f2fb0a225 984B / 984B                                                                      0.0s
 => => sha256:fba020fe61e2b15959ef887ea67c7fc61f77943d074889debe8d92e29402191f 529B / 529B                                                                      0.0s
 => => sha256:ba58cfa2eb92889af22a6fcf8c281a61599b0790c3912cd724549124cdfa4125 1.48kB / 1.48kB                                                                  0.0s
 => [2/3] RUN apt update     && apt install -y        autoconf        bash        bison        build-essential        flex        less        libssl-dev       13.7s
 => [3/3] RUN sh <<EOF > /build-script.sh                                                                                                                      40.7s
 => exporting to image                                                                                                                                          0.7s
 => => exporting layers                                                                                                                                         0.7s
 => => writing image sha256:741303d01bf0ff6d261961b8c8f613e7c1c4fccc2879144b04a7713bd8f15f69                                                                    0.0s
 => => naming to docker.io/library/ldms-slingshot-build                                                                                                         0.0s

View build details: docker-desktop://dashboard/build/desktop-linux/desktop-linux/khnv4eyhx21sw5y7xaz8k2nef

What's Next?
  View a summary of image vulnerabilities and recommendations → docker scout quickview
tar: Removing leading `/' from member names
LDMS Ubuntu Installation for ARM64 Slingshot Switch Samplers is at /Users/jkgreen/ldms_docker/archives/ovis_v4.4.3.tar.xz
```
