#!/bin/bash

BASE=openvas
NOCERT="--no-check-certificate"
GSA="greenbone-security-assistant-"
HINT="*"
RED='\033[0;31m'
GRE='\033[0;32m'
NOC='\033[0m'

declare -a _package_list=("-smb-" "-libraries-" "-scanner-" "-manager-" "-cli-")

function _install_prerequisites() {
  echo " "
  echo -e " ${GRE} ---------- DOWNLOADING DEPENDENCIES ---------- ${NOC} "
  apt install -y build-essential cmake gcc-mingw-w64 libgnutls28-dev perl-base heimdal-dev libpopt-dev libglib2.0-dev python-setuptools python-polib checkinstall libssh-dev libpcap-dev libxslt1-dev libgpgme11-dev uuid-dev bison libksba-dev libhiredis-dev libsnmp-dev libgcrypt20-dev libldap2-dev  libfreeradius-client-dev doxygen xmltoman sqlfairy sqlite3 redis-server gnutls-bin libsqlite3-dev texlive texlive-lang-german texlive-lang-english texlive-latex-recommended texlive-latex-extra libmicrohttpd-dev libxml2-dev libxslt1.1 xsltproc flex clang nmap rpm nsis alien
}

function _get_sources() {
  echo " "
  echo -e " ${GRE} ---------- DOWNLOADING SOURCES ---------- ${NOC} "
  wget http://wald.intevation.org/frs/download.php/2420/openvas-libraries-9.0.1.tar.gz ${NOCERT}
  echo " _> openvas-libraries-9.9.1 downloaded "
  wget http://wald.intevation.org/frs/download.php/2423/openvas-scanner-5.1.1.tar.gz ${NOCERT}
  echo " _> openvas-scanner-5.1.1 downloaded "
  wget http://wald.intevation.org/frs/download.php/2426/openvas-manager-7.0.2.tar.gz ${NOCERT}
  echo " _> openvas-manager-7.0.2 downloaded "
  wget http://wald.intevation.org/frs/download.php/2429/greenbone-security-assistant-7.0.2.tar.gz ${NOCERT}
  echo " _> greenbone-security-assistent-7.0.2 downloaded "
  wget http://wald.intevation.org/frs/download.php/2397/openvas-cli-1.4.5.tar.gz ${NOCERT}
  echo " _> openvas-cli-1.4.5 downloaded "
  wget https://github.com/greenbone/openvas-smb/archive/v1.0.4.tar.gz ${NOCERT}
  # use openvas-smb-1.0.4 for compatability. Other version will lead to errors during install becauseof undefined reference to `gnutls_certificate_type_set_priority`
  echo " _> openvas-smb-1.0.4 downloaded "
  #wget http://wald.intevation.org/frs/download.php/2401/ospd-1.2.0.tar.gz ${NOCERT}
  #wget http://wald.intevation.org/frs/download.php/2405/ospd-debsecan-1.2b1.tar.gz ${NOCERT}
  wget https://svn.wald.intevation.org/svn/openvas/branches/tools-attic/openvas-check-setup ${NOCERT}
  echo " _> openvas-check-setup script downloaded "
  find . -name \*.gz -exec tar zxvfp {} \;
  echo " _> downloaded files unpacked and folders created"
  chmod +x openvas-check-setup
  echo " _> openvas_check_setup is now executable"
  rm *.tar.gz
  echo " _> *.tar.gz files removed" 
  echo " "
}

function _install_sources() {
  echo " "
  echo -e " ${GRE} ---------- BUILDING SOURCES ---------- ${NOC} "
  DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null && pwd)"
  for p in "${_package_list[@]}"
  do
      echo " _> cd into openvas-$p"
      cd ${DIR}/${BASE}$p${HINT}/
      echo " _> create source folder"
      mkdir source && cd source
      echo " _> run cmake"
      cmake ..
      echo " _> run make"
      make
      echo " _> run make install and cd out of openvas-$p"
      make install && cd ../../
      echo " _> $p installed"
      echo " "
  done
  cd ${DIR}/$GSA${HINT}/
  mkdir source && cd source
  cmake ..
  make
  echo " _> run make install and cd out of openvas-$p"
  make install && cd ../../
  #cd ../../
  echo " _> $GSA installed"
  echo " "
}

function _remove_all() {
    echo " "
    echo -e " ${GRE} ---------- REMOVING PACKAGES ---------- ${NOC}  "
    dpkg -r "openvas-smb-${HINT}"
    echo " _> openvas-smb removed"
    dpkg -r "openvas-libraries"
    echo " _> libraries removed"
    dpkg -r "openvas-scanner-${HINT}"
    echo " _> openvas-scanner removed"
    dpkg -r "openvas-manager-${HINT}"
    echo " _> openvas-manager removed"
    dpkg -r "openvas-cli-${HINT}"
    echo " _> openvas-cli removed"
    dpkg -r "greenbone-security-assistant-${HINT}"
    echo " _> greenbone-security-assistant removed"
    echo " "
}

function _start_configuration() {
  echo " "
  echo -e " ${GRE} ---------- CONFIGURATION ---------- ${NOC} "
  cp /etc/redis/redis.conf /etc/redis/redis.orig
  echo " _> redis.conf backup complete"
  #echo "unixsocket /tmp/redis.sock" >> /etc/redis/redis.conf
  sed -i -- 's/# unixsocket /var/run/redis/redis.sock/unixsocket unixsocket /tmp/redis.sock/g' /etc/redis/redis.conf
  echo " _> redis set to use unixsocket"
  sed -i -- 's/# unixsocketperm 700/unixsocketperm 700/g' /etc/redis/redis.conf
  #echo "unixsocketperm 700" >> /etc/redis/redis.conf
  echo " _> permissions for unixsocket set"
  service redis-server restart
  openvas-manage-certs -a
  echo " _> certificates ready"
  ldconfig
  echo " _> ldconfig done"
  echo " "
}

function _create_user() {
  echo " "
  echo -e " ${GRE} ---------- CREATE USER ---------- ${NOC} "
  echo " _> Whats the name of the new user? "
  read name
  openvasmd --create-user=$name --role=Admin
  echo " _> Set new password for $name: "
  read pw
  openvasmd --user=$name --new-password=$pw
  echo " "
}

function _update_base() {
  echo " "
  echo -e " ${GRE} ---------- UPDATING DATA ---------- ${NOC} "
  /usr/local/sbin/greenbone-nvt-sync
  echo " _> - nvt sync done"
  /usr/local/sbin/greenbone-scapdata-sync
  echo " _> - scapdata sync done"
  /usr/local/sbin/greenbone-certdata-sync
  echo " _> - certdata sync done"
  echo " "
}

function _killing_services() {
  echo " "
  echo -e " ${GRE} ---------- KILLING PROCESSES ---------- ${NOC} "
  ps aux | egrep "(openvas|gsad)" | awk '{print $2}' | xargs -i kill -9 '{}'
  echo " _> openvassd killed"
  echo " _> openvasmd killed"
  echo " _> gsad killed"
  service redis-server stop
  echo " _> redis killed"
  echo " "
}

function _rebuild() {
  echo " "
  echo -e " ${GRE} ---------- REBUILDING NVT ---------- ${NOC} "
  /usr/local/sbin/openvasmd --rebuild --progress
  #/usr/local/sbin/openvasmd
  #echo " _> start openvasmd"
  /usr/local/sbin/gsad --http-only
  echo " _> - set --http-only"
  echo " "
}

function _launch_services() {
  echo " "
  echo -e " ${GRE} ---------- LAUNCHING SERVICES ---------- ${NOC} "
  redis-server /etc/redis/redis.conf
  echo " _> config for redis-server reloaded"
  /etc/init.d/redis-server start
  echo " _> redis-server started"
  /usr/local/sbin/openvasmd
  echo " _> openvasmd started"
  /usr/local/sbin/openvassd
  echo " _> openvassd started"
  /usr/local/sbin/gsad
  echo " _> gsad started"
  echo " "
}

function _show_usage() {
  echo " "
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
                echo "	--rebuild  : Rebuild NVT's and cache"
                #echo "	--remove  : Remove all packages"                
}

opt=$1
case $opt in
        "--install-pre")
                _install_prerequisites
                ;;
        "--get-src")
                _get_sources
                ;;
        "--install-src")
                _install_sources
                ;;
        "--configure")
                _start_configuration
                ;;
        "--create-usr")
                _create_user
                ;;
        "--update")
                _update_base
                ;;
         "--kill-services")
                _killing_services
                ;;
         "--rebuild")
                _rebuild
                ;;
         "--start")
                _launch_services
                #echo "OpenVAS is running on https://localhost:9392"
                ;;
         "--remove")
                _remove_all
                ;;
        *)
        	    echo "OpenVAS9 installer shell script utility"
              _show_usage  ;;
esac
