#!/usr/bin/env bash


# add deb-src to sources.list
sed -i "/deb-src/s/# //g" /etc/apt/sources.list

# install dep
apt update
apt install -y wget xz-utils make gcc flex bison dpkg-dev bc rsync kmod cpio libssl-dev aria2 git
apt build-dep -y linux

# change dir to workplace
cd "${GITHUB_WORKSPACE}" || exit

# download kernel source
aria2c https://mirrors.edge.kernel.org/pub/linux/kernel/v6.x/linux-6.7.tar.xz
mv *.tar.xz kernel.tar.xz
tar -xf kernel.tar.xz
cd linux-6.7 || exit

# copy config file
cp ../config .config

#patch cjktty
patch -Np1 < ../cjktty/cjktty-6.7.patch

# disable DEBUG_INFO to speedup build
scripts/config --disable DEBUG_INFO

# apply patches
# shellcheck source=src/util.sh
source ../patch.d/*.sh

# build deb packages
CPU_CORES=$(($(grep -c processor < /proc/cpuinfo)*2))
echo "y" | make deb-pkg -j"$CPU_CORES"

# move deb packages to artifact dir
cd ..
rm -rfv *dbg*.deb
mkdir "artifact"
mv ./*.deb artifact/
