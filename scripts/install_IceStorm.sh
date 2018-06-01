#!/bin/bash
platform=$1

install_tools () {
    echo "Installing prerequisites"
    sudo apt-get update
    sudo apt-get install build-essential clang bison flex libreadline-dev \
                         gawk tcl-dev libffi-dev git mercurial graphviz   \
                         xdot pkg-config python python3 libftdi-dev
}

create_swap () {
    echo "Createing swap memory"
    sudo mkdir -p /var/cache/swap/
    sudo dd if=/dev/zero of=/var/cache/swap/swapfile bs=1M count=512
    sudo chmod 0600 /var/cache/swap/swapfile
    sudo mkswap /var/cache/swap/swapfile
    sudo swapon /var/cache/swap/swapfile
    sudo echo "/var/cache/swap/swapfile        none    swap    sw      0       0">>/etc/fstab
}

install_icestorm () {
    echo "Installing the IceStorm Tools (icepack, icebox, iceprog, icetime, chip databases)"
    sudo git clone https://github.com/cliffordwolf/icestorm.git icestorm
    cd ./icestorm
    sudo make -j$(nproc)
    sudo make install
    cd ../
}

install_arachne () {
    echo "Installing Arachne-PNR (the place&route tool)"
    sudo git clone https://github.com/cseed/arachne-pnr.git arachne-pnr
    cd ./arachne-pnr
    sudo make -j$(nproc)
    sudo make install
    cd ../
}

install_yosys () {
    echo "Installing Yosys (Verilog synthesis)"
    sudo git clone https://github.com/cliffordwolf/yosys.git yosys
    cd ./yosys
    sudo make -j$(nproc)
    sudo make install
    cd ../
}

sudo mkdir tools
cd ./tools

install_tools

if [ "$platform"  ==  "BBB" ]; then
    create_swap
fi

install_icestorm
install_arachne
install_yosys

echo "IceStorm toolchain has been built and installed, please reboot"
