export SOURCE_BRANCH="4.12"
export SOURCE_VERSION="rc7"
export SOURCE_PLATFORM="bone1"

wget https://github.com/RobertCNelson/linux-stable-rcn-ee/archive/v$SOURCE_BRANCH-$SOURCE_VERSION.tar.gz
tar xf v$SOURCE_BRANCH-$SOURCE_VERSION.tar.gz

cd ./linux-stable-rcn-ee-$SOURCE_BRANCH-$SOURCE_VERSION

make -j3 mrproper ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- LOCALVERSION=-$SOURCE_VERSION-$SOURCE_PLATFORM

wget -c "http://rcn-ee.net/deb/jessie-armhf/v$SOURCE_BRANCH.0-$SOURCE_VERSION-$SOURCE_PLATFORM/defconfig" -O .config

make -j3 modules ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- LOCALVERSION=-$SOURCE_VERSION-$SOURCE_PLATFORM 2>&1

