# Build Dante Socks5 proxy
wget https://raw.githubusercontent.com/thien-tn/proxy-server/main/dante.sh -O dante.sh && bash dante.sh

# Build Squid HTTP and Dante Socks5 proxy on same VPS
wget https://raw.githubusercontent.com/thien-tn/proxy-server/main/httpsocks.sh -O httpsocks.sh && bash httpsocks.sh

# Build 3proxy HTTP/Socks5 proxy
wget https://raw.githubusercontent.com/thien-tn/proxy-server/main/3proxy.sh -O 3proxy.sh && bash 3proxy.sh
