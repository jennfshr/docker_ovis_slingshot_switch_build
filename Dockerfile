FROM ubuntu:latest
SHELL ["/bin/bash", "-c"]
RUN apt update \
    && apt install -y \
       autoconf \
       bash \
       bison \
       build-essential \
       devscripts \
       dh-make \
       flex \
       less \
       lintian \
       libssl-dev \
       libtool \
       make \
       git \
       pkg-config \
       python3-dev \
       vim
RUN bash <<EOF
set -x && mkdir -p ovis-ldms-debian-package && cd ovis-ldms-debian-package && export DEBEMAIL="jkgreen@sandia.gov" && export DEBFULLNAME="Jennifer K. Green" && echo "Cloning ovis" && git clone http://github.com/ovis-hpc/ovis.git -b v4.4.3 ovis-ldms-4.4.3 && tar cfJ ovis-ldms-4.4.3.tar.xz ovis-ldms-4.4.3 && cd ovis-ldms-4.4.3 && dh_make -i -y -f ../ovis-ldms-4.4.3.tar.xz -e jkgreen@sandia.gov -c bsd && [ -f debian/control ] && echo "Source: ovis-ldms
Priority: optional
Maintainer: Jennifer K. Green <jkgreen@sandia.gov>
Build-Depends:
 debhelper (>= 11),
 autoconf [arm64],
 bash [arm64],
 bison [arm64],
 build-essential [arm64],
 devscripts [arm64],
 dh-make [arm64],
 flex [arm64],
 less [arm64],
 lintian [arm64],
 libssl-dev [arm64],
 libtool [arm64],
 make [arm64],
 git [arm64],
 pkg-config [arm64],
 python3-dev [arm64]
Standards-Version: 4.1.3
Homepage: https://github.com/ovis-hpc/ovis

Package: ovis-ldms
Architecture: arm64
Depends:
 libssl-dev [arm64],
 python3-dev [arm64],
 bash [arm64]
Description: LDMS for SlingShot Switches
" > \$PWD/debian/control && echo "13" > \$PWD/debian/compat && echo -e "\\tdh_auto_configure -- --disable-infiniband --disable-papi --disable-opa2 --disable-tx2mon --disable-static --disable-perf --disable-store --disable-flatfile --disable-csv --disable-lustre --disable-clock --disable-synthetic --disable-varset --disable-lnet_stats --disable-gpumetrics --disable-coretemp --disable-array_example --disable-hello_stream --disable-blob_stream --disable-procinterrupts --disable-procnet --disable-procnetdev --disable-procnfs --disable-dstat --disable-procstat --disable-llnl-edac --disable-tsampler --disable-cray_power_sampler --disable-loadavg --disable-vmstat --disable-procdiskstats --disable-spaceless_names --disable-generic_sampler --disable-jobinfo-sampler --disable-app-sampler --disable-readline --with-slurm=no --disable-ibnet --disable-timescale-store --enable-slingshot_switch" >>\$PWD/debian/rules && cat \$PWD/debian/rules && debuild -uc -us
EOF