#!/bin/bash
# This is a simple automation that will write and utilize a Dockerfile
# to pull a debian image, and within it build from source tag v4.4.3 OVIS-HPC/ovis.git
# for the target platform arch (i.e., ARM64), then extract from the image a 
# archive that is able to be extracted onto a HPE Slingshot Switch
# usage: ./run_ldms_docker.sh

heredoc_dockerfile () {
cat << DOCKERFILE >Dockerfile
FROM docker.io/debian:buster

RUN apt update \\
    && apt install -y \\
       autoconf \\
       bash \\
       bison \\
       build-essential \\
       flex \\
       less \\
       libssl-dev \\
       libtool \\
       make \\
       git \\
       pkg-config
RUN sh <<EOF > /build.log
git clone http://github.com/ovis-hpc/ovis.git -b v4.4.3 && \\
cd ovis && \\
[ -x autogen.sh ] && ./autogen.sh &&
[ -x configure ] &&
./configure --prefix=${LDMS_PREFIX}
  --libdir=${LDMS_PREFIX}/lib64
  --disable-infiniband
  --disable-papi
  --disable-opa2
  --disable-tx2mon
  --disable-static
  --disable-perf
  --disable-store
  --disable-flatfile
  --disable-csv
  --disable-lustre
  --disable-clock
  --disable-synthetic
  --disable-varset
  --disable-lnet_stats
  --disable-gpumetrics
  --disable-coretemp
  --disable-array_example
  --disable-hello_stream
  --disable-blob_stream
  --disable-procinterrupts
  --disable-procnet
  --disable-procnetdev
  --disable-procnfs
  --disable-dstat
  --disable-procstat
  --disable-llnl-edac
  --disable-tsampler
  --disable-cray_power_sampler
  --disable-loadavg
  --disable-vmstat
  --disable-procdiskstats
  --disable-spaceless_names
  --disable-generic_sampler
  --disable-jobinfo-sampler
  --disable-app-sampler
  --disable-readline
  --with-slurm=no
  --disable-ibnet
  --disable-timescale-store
  --enable-slingshot_switch CFLAGS='-g -O0' n
  make -j && make install
EOF
DOCKERFILE
}
#REGISTRY_URL="https://index.docker.io/v1/"
read -s -p "Enter Docker Hub Username: " DOCKER_USERNAME
echo ""
read -s -p "Enter Docker Hub Password: " DOCKER_PASSWORD
echo ""
echo "$DOCKER_PASSWORD" | docker login -u ${DOCKER_USERNAME} --password-stdin 
#echo "$DOCKER_PASSWORD" | docker login $REGISTRY_URL -u ${DOCKER_USERNAME} --password-stdin 
unset DOCKER_PASSWORD

LDMS_PREFIX="/ovis_v4.4.3"
heredoc_dockerfile
docker build -t ldms-slingshot-build .
LDMS_ARTIFACT_PATH=${PWD}/archives
mkdir -p $LDMS_ARTIFACT_PATH
docker run --entrypoint tar ldms-slingshot-build cjf - ${LDMS_PREFIX} > ${LDMS_ARTIFACT_PATH}${LDMS_PREFIX}.tar.xz
[ -f ${LDMS_ARTIFACT_PATH}${LDMS_PREFIX}.tar.xz ] && echo "LDMS Ubuntu Installation for ARM64 Slingshot Switch Samplers is at $(readlink -f ${LDMS_ARTIFACT_PATH}${LDMS_PREFIX}.tar.xz)"

#docker run --rm -ti \\
#docker run -ti \
#    -v ${LDMS_ARTIFACT_PATH}:$LDMS_PREFIX:rw \
#    ldms-slingshot-build

