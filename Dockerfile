FROM ubuntu:20.04
ARG DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-c"]
RUN apt update \
    && apt list --upgradable \
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
       python3 \
       python3-dev \
       ca-certificates \
       dpkg-sig \
       vim
RUN bash <<EOF
set -x && \
mkdir -p ovis-ldms-debian-package && \
cd ovis-ldms-debian-package && \
export DEBEMAIL="jkgreen@sandia.gov" && \
export DEBFULLNAME="Jennifer K. Green" && \
export DEB_BUILD_OPTIONS='parallel=16' && \
echo "Cloning ovis" && \
git clone http://github.com/ovis-hpc/ovis.git -b v4.4.3 ovis-ldms-4.4.3 && \
tar cfJ ovis-ldms-4.4.3.tar.xz ovis-ldms-4.4.3 && \
cd ovis-ldms-4.4.3 && \
dh_make -i -y -f ../ovis-ldms-4.4.3.tar.xz -e jkgreen@sandia.gov -c bsd && \
[ -f debian/control ] && \
echo "Source: ovis-ldms
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
 python3 [arm64],
 python3-dev [arm64],
Standards-Version: 4.1.3
Homepage: https://github.com/ovis-hpc/ovis

Package: ovis-ldms
Architecture: arm64
Depends:
 libssl-dev [arm64],
 python3-dev [arm64],
 bash [arm64]
Description: LDMS for SlingShot Switches
" > \$PWD/debian/control && \
cat \$PWD/debian/control && \
echo "13" > \$PWD/debian/compat && \
echo -e "\\tdh_auto_configure -- --disable-infiniband --disable-papi --disable-opa2 --disable-tx2mon --disable-static --disable-perf --disable-store --disable-flatfile --disable-csv --disable-lustre --disable-clock --disable-synthetic --disable-varset --disable-lnet_stats --disable-gpumetrics --disable-coretemp --disable-array_example --disable-hello_stream --disable-blob_stream --disable-procinterrupts --disable-procnet --disable-procnetdev --disable-procnfs --disable-dstat --disable-procstat --disable-llnl-edac --disable-tsampler --disable-cray_power_sampler --disable-loadavg --disable-vmstat --disable-procdiskstats --disable-spaceless_names --disable-generic_sampler --disable-jobinfo-sampler --disable-app-sampler --disable-readline --with-slurm=no --disable-ibnet --disable-timescale-store --enable-slingshot_switch" >>\$PWD/debian/rules && \
cat \$PWD/debian/rules && debuild -uc -us && \
printf 'do_hash() {\n  HASH_NAME=\$1\n  HASH_CMD=\$2\n  echo "\${HASH_NAME}:"\n  for f in \$(find -type f); do\n    f=\$(echo \$f | cut -c3-)\n    if [ "\$f" = "Release" ]; then\n      continue\n    fi\n    echo " \$(\${HASH_CMD} \${f}  | cut -d" " -f1) \$(wc -c \$f)"\n  done\n}\n' >> /root/.bash_custom_functions && \
source /root/.bash_custom_functions && \
mkdir -p /root/ovis-ldms/apt-repo/dists/stable/main/binary-arm64 && \
mkdir -p /root/ovis-ldms/apt-repo/pool/main && \
[ -f /ovis-ldms-debian-package/ovis-ldms_4.4.3-1_arm64.deb ] && \
deb_pkg_dir=\$(dirname \$(readlink -f /ovis-ldms-debian-package/ovis-ldms_4.4.3-1_arm64.deb)) && \
cp /ovis-ldms-debian-package/ovis-ldms_4.4.3-1_arm64.deb /root/ovis-ldms/apt-repo/pool/main/. && \
cd /root/ovis-ldms/apt-repo && \
dpkg-scanpackages --arch arm64 pool/ > dists/stable/main/binary-arm64/Packages && \
cat dists/stable/main/binary-arm64/Packages | gzip -9 > dists/stable/main/binary-arm64/Packages.gz && \
cd dists/stable && \
printf "Architectures: arm64\nComponents: main\nDate: \$(date -Ru)\nVersion: 4.4.3-1\nSuite: stable" > Release && \
do_hash "MD5Sum" "md5sum" >> Release && \
do_hash "SHA1" "sha1sum" >> Release && \
do_hash "SHA256" "sha256sum" >> Release && \
cat Release && \
echo "<<<<<<<<<<< dpkg-scanpackages complete >>>>>>>>>>>>>>" && \
mkdir -p /root/.gnupg && \
chmod 0700 /root/.gnupg && \
echo "\${GPG_PASSWORD}" > /root/.gnupg/gpg_pwd.txt && \
chmod 0600 /root/.gnupg/gpg_pwd.txt && \
echo "\${GPG_PUBLIC_KEY}" > /root/.gnupg/public.key && \
echo "\${GPG_PRIVATE_KEY}" > /root/.gnupg/private.key && \
chmod 0700 /root/.gnupg && \
chmod 0600 /root/.gnupg/*.key && \
gpg -v --batch --import /root/.gnupg/public.key && \
gpg -v --batch --import /root/.gnupg/private.key && \
GPG_KEY=( \$(gpg --list-keys --keyid-format=long | grep "^pub"| awk '{print \$2}' | awk -F'/' '{print \$2}') ) && \
echo -e "\$GPG_USERNAME\n\$GPG_EMAIL\nNo Comment\no\n" | gpg --batch --command-fd 0 --expert --edit-key \${GPG_KEY[1]} adduid && \
echo -e "5\ny\n" | gpg --batch --command-fd 0 --expert --edit-key \${GPG_KEY[1]} trust && \
gpg --list-keys \${GPG_USERNAME} && \
cd \${deb_pkg_dir} && file ovis-ldms_4.4.3-1_arm64.deb && \
printf "\${GPG_PASSWORD}" > /root/.gnupg/gpg-passwd.txt && \
printf "use-agent\npinentry-mode loopback" > /root/.gnupg/gpg.conf && \
printf "allow-loopback-pinentry" > /root/.gnupg/gpg-agent.conf && \
echo RELOADAGENT | gpg-connect-agent && \
tty=/usr/bin/tty && \
export GPG_TTY=\$tty && \
ls -al ovis-ldms_4.4.3-1_arm64.deb && \
echo "\$(pwd)/ovis-ldms_4.4.3-1_arm64.deb is \$(file ovis-ldms_4.4.3-1_arm64.deb)" && \
dpkg-sig -k \${GPG_KEY[1]} --gpg-options '--passphrase-file /root/.gnupg/gpg-passwd.txt' --sign builder ovis-ldms_4.4.3-1_arm64.deb 
EOF
