#!/bin/bash

BASE=openvas
ASTERIKS="*"
NOCERT="--no-check-certificate"
GSA="greenbone-security-assistant-"

declare -a _package_list=("-smb-" "-libraries-" "-scanner-" "-manager-" "-cli-")

function _install_prerequisites() {
  apt install -y build-essential cmake gcc-mingw-w64 libgnutls28-dev perl-base heimdal-dev libpopt-dev libglib2.0-dev libssh-dev libpcap-dev libgpgme11-dev uuid-dev bison libksba-dev libhiredis-dev libsnmp-dev libgcrypt20-dev libldap2-dev libfreeradius-client-dev doxygen xmltoman sqlfairy sqlite3 redis-server gnutls-bin libsqlite3-dev texlive texlive-lang-german texlive-lang-english texlive-latex-recommended texlive-latex-extra libmicrohttpd-dev libxml2-dev libxslt1.1 xsltproc flex clang nmap rpm nsis alien
}

function _get_sources() {
  wget http://wald.intevation.org/frs/download.php/2420/openvas-libraries-9.0.1.tar.gz ${NOCERT}
  wget http://wald.intevation.org/frs/download.php/2423/openvas-scanner-5.1.1.tar.gz ${NOCERT}
  wget http://wald.intevation.org/frs/download.php/2426/openvas-manager-7.0.2.tar.gz ${NOCERT}
  wget http://wald.intevation.org/frs/download.php/2429/greenbone-security-assistant-7.0.2.tar.gz ${NOCERT}
  wget http://wald.intevation.org/frs/download.php/2397/openvas-cli-1.4.5.tar.gz ${NOCERT}
  wget http://wald.intevation.org/frs/download.php/2377/openvas-smb-1.0.4.tar.gz ${NOCERT}
  #wget http://wald.intevation.org/frs/download.php/2401/ospd-1.2.0.tar.gz ${NOCERT}
  #wget http://wald.intevation.org/frs/download.php/2405/ospd-debsecan-1.2b1.tar.gz ${NOCERT}
  wget https://svn.wald.intevation.org/svn/openvas/branches/tools-attic/openvas-check-setup ${NOCERT}
  
  find . -name \*.gz -exec tar zxvfp {} \;
  chmod +x openvas-check-setup
  
  echo "-- Removing *.tar.gz files"
  rm *.tar.gz
}

function _install_sources() {
  echo "-- BUILDING SOURCES"
  DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null && pwd)"
  for p in "${_package_list[@]}"
  do
      cd ${DIR}/${BASE}$p${ASTERIKS}/
      mkdir source && cd source
      cmake ..
      make
      make install && cd ../../
      echo "( OK ) - $p installed"
  done
  cd ${DIR}/$GSA${ASTERIKS}/
  mkdir source && cd source
  cmake ..
  make
  make install && cd ../../
  
}

function _start_configuration() {
  echo "-- CONFIGURATION"
  echo "		-- configure redis-server"
  cp /etc/redis/redis.conf /etc/redis/redis.orig
  echo „unixsocket /tmp/redis.sock“ >> /etc/redis/redis.conf
  echo „unixsocketperm 700“ >> /etc/redis/redis.conf
  service redis-server restart
  echo "		-- manage certificates"
  openvas-manage-certs –a
  echo "		-- create, udpate and remove symbolic links"
  ldconfig
  echo "CONFIGURATION COMPLETE"
}

function _create_user() {
  echo "-- CREATE USER"
  echo "Whats the name of the new user? "
  read name
  openvasmd --create-user=$name --role=Admin
  echo "Set you new password: "
  read pw
  openvasmd --user=$name --new-password=$pw
  
}

function _update_base() {
  echo "-- UPDATING DATA"
  echo "		-- Run nvt sync"
  /usr/local/sbin/greenbone-nvt-sync
  echo "		-- Run scapdata sync"
  /usr/local/sbin/greenbone-scapdata-sync
  echo "		-- Run certdata sync"
  /usr/local/sbin/greenbone-certdata-sync
}

function _killing_services() {
  echo "-- KILLING PROCESSES"
  echo "		-- openvas"
  echo "		-- gsad"
  echo "		-- redis"
  ps aux | egrep "(openvas|gsad|redis-server)" | awk '{print $2}' | xargs -i kill -9 '{}'
  service redis-server stop
  
}

function _launch_services() {
  echo "-- LAUNCHING SERVICES"
  echo "		-- Reload config for redis-server"
  redis-server /etc/redis/redis.conf
  echo "		-- Start redis-server"
  /etc/init.d/redis-server start
  echo "		-- Start openvasmd"
  /usr/local/sbin/openvasmd
  echo "		-- Start openvassd"
  /usr/local/sbin/openvassd
  echo "		-- Start gsad"
  /usr/local/sbin/gsad
}

function _show_usage() {
  echo "Usage: $0 OPTION"
                echo "Available OPTIONS:"
                echo "	--install-pre  : Download needed Ubuntu 16.04 packages"
                echo "	--get-src  : Download needed source files/ folders for OpenVAS"
                echo "	--install-src  : Build source files/ folders for OpenVAS"
                echo "	--configure  : Create certificates and prepare redis-server"
                echo "	--create-usr  : Create new user for OpenVAS WEBUI" 
                echo "	--update  : Run sync for nvt, scapdata and certdata"
                echo "	--kill-services  : Shutdown running services before launching OpenVAS9" 
                echo "	--start  : Launch OpenVAS9"
}

opt=$1
case $opt in
        "--install-pre")
                echo "Downloading / installing needed dependencies..."
                _install_prerequisites
                ;;
        "--get-src")
                echo "Downloading sources..."
                _get_sources
                ;;
        "--install-src")
                echo "Building / installing source files..."
                _install_sources
                ;;
        "--configure")
                echo "Configuring openVAS9..."
                _start_configuration
                ;;
        "--create-usr")
                echo "Creating user..."
                _create_user
                ;;
        "--update")
                echo "Running update..."
                _update_base
                ;;
         "--kill-services")
                echo "Shutting down active services..."
                _killing_services
                ;;
         "--start")
                echo "Starting services..."
                _launch_services
                echo "OpenVAS is running on https://localhost:9392"
                ;;
        *)
        	    echo "OpenVAS9 installer shell script utility"
              _show_usage  ;;
esac



