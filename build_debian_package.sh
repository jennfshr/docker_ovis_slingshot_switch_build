#!/bin/bash
# This is a simple automation that will write and utilize a Dockerfile
# to pull a debian image, and within it build from source tag v4.4.3 OVIS-HPC/ovis.git
# for the target platform arch (i.e., ARM64), then extract from the image a
# archive that is able to be extracted onto a HPE Slingshot Switch
# usage: ./run_ldms_docker.sh

heredoc_dockerfile () {
cat << DOCKERFILE >Dockerfile
FROM docker.io/debian:buster
SHELL ["/bin/bash", "-c"]
RUN apt update \\
    && apt install -y \\
       autoconf \\
       bash \\
       bison \\
       build-essential \\
       devscripts \\
       dh-make \\
       flex \\
       less \\
       lintian \\
       libssl-dev \\
       libtool \\
       make \\
       git \\
       pkg-config \\
       python3-dev \\
       vim
RUN bash <<EOF
set -x && \
mkdir -p ovis-ldms-debian-package && \
cd ovis-ldms-debian-package && \
export DEBEMAIL="$DEBEMAIL" && \
export DEBFULLNAME="$DEBFULLNAME" && \
export DEB_BUILD_ARCH="arm64" && \
echo "Cloning ovis" && \
git clone http://github.com/ovis-hpc/ovis.git -b v4.4.3 ovis-ldms-4.4.3 && \
tar cfJ ovis-ldms-4.4.3.tar.xz ovis-ldms-4.4.3 && \
cd ovis-ldms-4.4.3 && \
dh_make -i -y -f ../ovis-ldms-4.4.3.tar.xz -e jkgreen@sandia.gov -c bsd && \
[ -f debian/control ] && \
echo "\
Source: ovis-ldms
Priority: optional
Maintainer: $DEBFULLNAME <$DEBEMAIL>
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
Architecture: $DEB_BUILD_ARCH
Depends:
 libssl-dev [arm64],
 python3-dev [arm64],
 bash [arm64]
Description: LDMS for SlingShot Switches
" > \\\$PWD/debian/control && \
echo "HERE >>>>" && \
cat \\\$PWD/debian/control && \
echo "\
     Key-Type: DSA
     Key-Length: 1024
     Subkey-Type: ELG-E
     Subkey-Length: 1024
     Name-Real: $DEBFULLNAME
     Name-Email: $DEBEMAIL
     Expire-Date: 0
     Passphrase: $GPGPASS
" >/tmp/gpgkeygen && \
[ -f /tmp/gpgkeygen ] && gpg --full-gen-key --batch /tmp/gpgkeygen && \
[ -f debian/rules ] && \
echo "Done with gpgkeygen" && \
echo -e "\\\\\tdh_auto_configure \
-- \
--disable-infiniband \
--disable-papi \
--disable-opa2 \
--disable-tx2mon \
--disable-static \
--disable-perf \
--disable-store \
--disable-flatfile \
--disable-csv \
--disable-lustre \
--disable-clock \
--disable-synthetic \
--disable-varset \
--disable-lnet_stats \
--disable-gpumetrics \
--disable-coretemp \
--disable-array_example \
--disable-hello_stream \
--disable-blob_stream \
--disable-procinterrupts \
--disable-procnet \
--disable-procnetdev \
--disable-procnfs \
--disable-dstat \
--disable-procstat \
--disable-llnl-edac \
--disable-tsampler \
--disable-cray_power_sampler \
--disable-loadavg \
--disable-vmstat \
--disable-procdiskstats \
--disable-spaceless_names \
--disable-generic_sampler \
--disable-jobinfo-sampler \
--disable-app-sampler \
--disable-readline \
--with-slurm=no \
--disable-ibnet \
--disable-timescale-store \
--enable-slingshot_switch" >>\\\$PWD/debian/rules && \
cat \\\$PWD/debian/rules && \
debuild -uc -us
EOF
DOCKERFILE
}

#cd debian/tmp &&
#git clone https://github.com/jennfshr/docker_ovis_slingshot_switch_build.git &&
#dh_install --autodest --sourcedir docker_ovis_slingshot_switch_build/gen_switch_config.sh
#REGISTRY_URL="https://index.docker.io/v1/"
read -s -p "Enter Docker Hub Username: " DOCKER_USERNAME
echo ""
read -s -p "Enter Docker Hub Password: " DOCKER_PASSWORD
echo ""
echo "$DOCKER_PASSWORD" | docker login $REGISTRY_URL -u ${DOCKER_USERNAME} --password-stdin
unset DOCKER_PASSWORD
read -s -p "Enter DEBFULLNAME: " DEBFULLNAME
DEBFULLNAME="${DEBFULLNAME}"
echo ""
read -s -p "Enter DEBEMAIL: " DEBEMAIL
#DEBEMAIL="\"$(echo $DEBEMAIL)\""
echo ""
read -s -p "Enter GPG Signing Passphrase to Use: " GPGPASS
echo ""
DEB_BUILD_ARCH="arm64"

# Setup the Dockerfile via a heredoc function (adjustable above ^^)
LDMS_PREFIX="/ovis_v4.4.3"
[ -f Dockerfile ] && rm Dockerfile
heredoc_dockerfile
docker build -t ldms-slingshot-build .

# Establish a staging area for the archive, then a "tar" entrypoint to redirect there
LDMS_ARTIFACT_PATH="${PWD}/archives"
[ -f ${LDMS_ARTIFACT_PATH}/${LDMS_PREFIX//\/}.tar.xz ] && \
  mv ${LDMS_ARTIFACT_PATH}/${LDMS_PREFIX//\/}.tar.xz \
  ${LDMS_ARTIFACT_PATH}/${LDMS_PREFIX//\/}.tar.xz.$(date +%m-%d-%y"-"%H.%M.%S)
mkdir -p $LDMS_ARTIFACT_PATH

docker run --entrypoint tar ldms-slingshot-build \
                        cjf - ovis-ldms-debian-package \
                        > ${LDMS_ARTIFACT_PATH}/${LDMS_PREFIX//\/}.tar.xz

# Sanity Check the created archive

[ -f ${LDMS_ARTIFACT_PATH}/${LDMS_PREFIX//\/}.tar.xz ] && \
  echo "LDMS Ubuntu Installation for ARM64 Slingshot Switch Samplers \
  is at $(readlink -f ${LDMS_ARTIFACT_PATH}/${LDMS_PREFIX//\/}.tar.xz)" ||
  echo "Archive at ${LDMS_ARTIFACT_PATH}/${LDMS_PREFIX//\/}.tar.xz not found!"
# Sanity Check the sampler libs and script staging in archive
tar --extract --file=${LDMS_ARTIFACT_PATH}/${LDMS_PREFIX//\/}.tar.xz \
  ovis-ldms-debian-package/ovis-ldms_4.4.3-1_arm64.deb \
  && file ovis-ldms-debian-package/*.deb \
  && cp ovis-ldms-debian-package/ovis-ldms_4.4.3-1_arm64.deb archives/. \
  && echo "Debian Package at $(readlink -f archives/ovis-ldms_4.4.3-1_arm64.deb)" \
  && echo "Debian arm64 LDMS Slingshot Switch Sampler Package Build is Complete"
