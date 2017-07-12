export SOURCE_BRANCH="4.12"
export SOURCE_VERSION="rc7"
export SOURCE_PLATFORM="bone1"

wget -c https://releases.linaro.org/components/toolchain/binaries/5.3-2016.02/arm-linux-gnueabihf/gcc-linaro-5.3-2016.02-x86_64_arm-linux-gnueabihf.tar.xz
tar xf gcc-linaro-5.3-2016.02-x86_64_arm-linux-gnueabihf.tar.xz
export CC=$PWD/gcc-linaro-5.3-2016.02-x86_64_arm-linux-gnueabihf/bin/arm-linux-gnueabihf-

echo "Using:" 
${CC}gcc --version

wget https://github.com/RobertCNelson/linux-stable-rcn-ee/archive/v$SOURCE_BRANCH-$SOURCE_VERSION.tar.gz
tar xf v$SOURCE_BRANCH-$SOURCE_VERSION.tar.gz

cd ./linux-stable-rcn-ee-$SOURCE_BRANCH-$SOURCE_VERSION

make -j3 mrproper ARCH=arm CROSS_COMPILE=${CC}
wget -c "http://rcn-ee.net/deb/jessie-armhf/v$SOURCE_BRANCH.0-$SOURCE_VERSION-$SOURCE_PLATFORM/defconfig" -O .config
make -j3 modules ARCH=arm CROSS_COMPILE=${CC}
