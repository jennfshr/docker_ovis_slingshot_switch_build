#!/bin/bash
#
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
       vim \\
       git \\
       tar \\
       pkg-config
RUN sh <<EOF > /build-script.sh
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
  make -j && make install &&
cd / &&
tar cvfj ${LDMS_PREFIX}.tar.xz ${LDMS_PREFIX} &&
readlink -f ${LDMS_PREFIX}.tar.xz
EOF
DOCKERFILE
#FROM docker.io/debian:buster
#
#RUN apt update \\
    #&& apt install -y \\
       #autoconf \\
       #bison \\
       #build-essential \\
       #flex \\
       #less \\
       #libssl-dev \\
       #libtool \\
       #make \\
       #vim \\
       #git \\
       #pkg-config
#RUN sh <<EOF > /build-script.sh
#git clone http://github.com/ovis-hpc/ovis.git -b v4.4.3 && 
#pushd ovis && 
#[ -x autogen.sh ] && ./autogen.sh && 
#[ -x configure ] && 
#./configure --prefix=/rwfs/ovis_v4.4.3 
  #--libdir=/rwfs/ovis_v4.4.3/lib64 
  #--disable-infiniband 
  #--disable-papi 
  #--disable-opa2 
  #--disable-tx2mon 
  #--disable-static 
  #--disable-perf 
  #--disable-store 
  #--disable-flatfile 
  #--disable-csv 
  #--disable-lustre 
  #--disable-clock 
  #--disable-synthetic 
  #--disable-varset 
  #--disable-lnet_stats 
  #--disable-gpumetrics 
  #--disable-coretemp 
  #--disable-array_example 
  #--disable-hello_stream 
  #--disable-blob_stream 
  #--disable-procinterrupts 
  #--disable-procnet 
  #--disable-procnetdev 
  #--disable-procnfs 
  #--disable-dstat 
  #--disable-procstat 
  #--disable-llnl-edac 
  #--disable-tsampler 
  #--disable-cray_power_sampler 
  #--disable-loadavg 
  #--disable-vmstat 
  #--disable-procdiskstats 
  #--disable-spaceless_names 
  #--disable-generic_sampler 
  #--disable-jobinfo-sampler 
  #--disable-app-sampler 
  #--disable-readline 
  #--with-slurm=no 
  #--disable-ibnet 
  #--disable-timescale-store 
  #--enable-slingshot_switch CFLAGS='-g -O0' \n\
#make -j && make install && 
#pushd /rwfs/ && 
#tar cvfj ovis_v4.4.3.tar.xz ovis_v4.4.3 && 
#readlink -f ovis_v4.4.3.tar.xz
#EOF
#
#FROM scratch
#COPY --from=0 /rwfs/ovis_v4.4.3 /rwfs/ovis_v4.4.3
#CMD ["/rwfs/ovis_v4.4.3/sbin/ldmsd --version"
#DOCKERFILE
}
#REGISTRY_URL="https://index.docker.io/v1/"
read -s -p "Enter Docker Hub Username: " DOCKER_USERNAME
echo ""
read -s -p "Enter Docker Hub Password: " DOCKER_PASSWORD
echo ""
echo "$DOCKER_PASSWORD" | docker login -u ${DOCKER_USERNAME} --password-stdin 
#echo "$DOCKER_PASSWORD" | docker login $REGISTRY_URL -u ${DOCKER_USERNAME} --password-stdin 
unset DOCKER_PASSWORD

#heredoc_buildscript
#[ -f build_script.sh ] && LDMS_SCRIPT_PATH=$(readlink -f build_script.sh)
LDMS_PREFIX="/ovis_v4.4.3"
heredoc_dockerfile
[ -f Dockerfile ] && cat Dockerfile

docker build -t ldms-slingshot-build .
#git clone git@github.com:ovis-hpc/ovis.git -b v4.4.3
#LDMS_SOURCE_PATH=$(readlink -f $(dirname $0))
LDMS_ARTIFACT_PATH=${PWD}/ovis_v4.4.3
docker run --entrypoint tar ldms-slingshot-build czf - ${LDMS_PREFIX} > ${LDMS_PREFIX//\/}.tar.gz

#docker run --rm -ti \\
#docker run -ti \
#    -v ${LDMS_ARTIFACT_PATH}:$LDMS_PREFIX:rw \
#    ldms-slingshot-build

