yum -y install openssl openssl-devel
yum -y install automake autoconf libtool make
yum -y install gcc gcc-c++
yum -y install git
git clone https://github.com/madeye/shadowsocks-libev.git
cd shadowsocks-libev
./configure
make && make install
cd /usr/local/bin/
iptables -F
echo "Input VPS ip address:"
read ip

echo "Input Password:"
read password
command="nohup ss-server -s ${ip} -p 443 -l 1080 -k ${password} -m aes-256-cfb &"
nohup ss-server -s ${ip} -p 443  -k ${password} -m aes-256-cfb &
echo -e "\n\n"
echo "Information:"
echo "Server Ip:${ip}"
echo "Server Port: 443"
echo "Password:${password}"
echo "encrypt_method: aes-256-cfb "
