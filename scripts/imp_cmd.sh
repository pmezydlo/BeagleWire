#Handful mportant commands to setup your BBB boards

#static ip
sudo connmanctl services
sudo connmanctl config <services> --ipv4 manual 192.168.20.101 255.255.255.0 192.168.20.1
sudo connmanctl config <services> --nameservers 8.8.8.8

#route internet to BB
sudo iptables -t nat -A POSTROUTING -o wlp5s0 -j MASQUERADE
sudo iptables -A FORWARD -i enp4s0 -j ACCEPT
sudo sysctl net.ipv4.ip_forward=1

#program fpga device
dd if=example.bin of=/dev/spidev1.0 
