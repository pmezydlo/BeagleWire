export SOURCE_BRANCH="4.12"
export SOURCE_VERSION="rc1-bone0"
export SOURCE_REPO="linux-stable-rcn-ee"
export SOURCE_LOCATION="https://github.com/RobertCNelson"
wget "$SOURCE_LOCATION/$SOURCE_REPO/archive/$SOURCE_BRANCH-$SOURCE_VERSION.tar.gz"
tar -xf $SOURCE_BRANCH-$SOURCE_VERSION.tar.gz

cd "$SOURCE_REPO-$SOURCE_BRANCH-$SOURCE_VERSION/"


make -j9 mrproper ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- LOCALVERSION=-$SOURCE_VERSION
wget -c "http://rcn-ee.net/deb/jessie-armhf/v$SOURCE_BRANCH.0-$SOURCE_VERSION/defconfig" -O .config
make -j9 menuconfig ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- LOCALVERSION=-$SOURCE_VERSION
make -j9 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- LOCALVERSION=-$SOURCE_VERSION 2>&1 

