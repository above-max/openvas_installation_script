#!/bin/bash

BASE=openvas
NOCERT="--no-check-certificate"
GSA="greenbone-security-assistant-"
HINT="*"

declare -a _package_list=("-smb-" "-libraries-" "-scanner-" "-manager-" "-cli-")

function _install_prerequisites() {
  echo " "
  echo " ↪ ☰☰☰☰☰☰☰☰☰☰ -- DOWNLOADING DEPENDENCIES -- ☰☰☰☰☰☰☰☰☰☰"
  apt install -y build-essential cmake gcc-mingw-w64 libgnutls28-dev perl-base heimdal-dev libpopt-dev libglib2.0-dev libssh-dev libpcap-dev libxslt1-dev libgpgme11-dev uuid-dev bison libksba-dev libhiredis-dev libsnmp-dev libgcrypt20-dev libldap2-dev  libfreeradius-client-dev doxygen python-setuptools python-paramiko python-polib xmltoman sqlfairy sqlite3 redis-server gnutls-bin libsqlite3-dev texlive texlive-lang-german texlive-lang-english texlive-latex-recommended texlive-latex-extra libmicrohttpd-dev libxml2-dev libxslt1.1 xsltproc flex clang nmap rpm nsis alien checkinstall
}

function _get_sources() {
  echo " "
  echo " ↪ ☰☰☰☰☰☰☰☰☰☰ -- DOWNLOADING SOURCES -- ☰☰☰☰☰☰☰☰☰☰"
  wget http://wald.intevation.org/frs/download.php/2420/openvas-libraries-9.0.1.tar.gz ${NOCERT}
  echo " ✔ - openvas-libraries-9.9.1 downloaded "
  wget http://wald.intevation.org/frs/download.php/2423/openvas-scanner-5.1.1.tar.gz ${NOCERT}
  echo " ✔ - openvas-scanner-5.1.1 downloaded "
  wget http://wald.intevation.org/frs/download.php/2426/openvas-manager-7.0.2.tar.gz ${NOCERT}
  echo " ✔ - openvas-manager-7.0.2 downloaded "
  wget http://wald.intevation.org/frs/download.php/2429/greenbone-security-assistant-7.0.2.tar.gz ${NOCERT}
  echo " ✔ - greenbone-security-assistent-7.0.2 downloaded "
  wget http://wald.intevation.org/frs/download.php/2397/openvas-cli-1.4.5.tar.gz ${NOCERT}
  echo " ✔ - openvas-cli-1.4.5 downloaded "
  wget http://wald.intevation.org/frs/download.php/2377/openvas-smb-1.0.4.tar.gz ${NOCERT}
  echo " ✔ - openvas-smb-1.0.4 downloaded "
  #wget http://wald.intevation.org/frs/download.php/2401/ospd-1.2.0.tar.gz ${NOCERT}
  #wget http://wald.intevation.org/frs/download.php/2405/ospd-debsecan-1.2b1.tar.gz ${NOCERT}
  wget https://svn.wald.intevation.org/svn/openvas/branches/tools-attic/openvas-check-setup ${NOCERT}
  echo " ✔ - openvas-check-setup script downloaded "
  find . -name \*.gz -exec tar zxvfp {} \;
  echo " ✔ - downloaded files unpacked and folders created"
  chmod +x openvas-check-setup
  echo " ✔ - openvas_check_setup is now executable"
  rm *.tar.gz
  echo " ✔ - *.tar.gz files removed"
}

function _install_sources() {
  echo " "
  echo " ↪ ☰☰☰☰☰☰☰☰☰☰ -- BUILDING SOURCES -- ☰☰☰☰☰☰☰☰☰☰"
  DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null && pwd)"
  for p in "${_package_list[@]}"
  do
      echo " ➜ - cd into openvas-$p"
      cd ${DIR}/${BASE}$p${HINT}/
      echo " ➜ - create source folder"
      mkdir source && cd source
      echo " ➜ - run cmake"
      cmake ..
      echo " ➜ - run make"
      make
      #echo " ➜ - get version no. from openvas-$p"
      #version=`pwd | sed 's/\//\n/g' | grep "${BASE}$p" | sed "s/${BASE}$p//"`
      echo " ➜ - openvas-$p using checkinstall"
      checkinstall --pkgname "${BASE}$p" --maintainer "openvas_installation_script" -y
      #make install && cd ../../
      cd ../../
      echo " ✔ - $p installed"
      echo " ☰☰☰☰☰☰☰☰☰☰☰☰☰☰☰☰☰☰☰☰ "
  done
  cd ${DIR}/$GSA${HINT}/
  mkdir source && cd source
  cmake ..
  make
  echo " ➜ - get version no. from openvas-$p"
  version=`pwd | sed 's/\//\n/g' | grep "$GSA" | sed "s/$GSA//"`
  echo " ➜ - openvas-$p using checkinstall"
  checkinstall --pkgname "GSA" --pkgversion "$version" --maintainer "openvas_installation_script" -y
  #make install && cd ../../
  cd ../../
  echo " ✔ - $GSA installed"
  echo " ☰☰☰☰☰☰☰☰☰☰☰☰☰☰☰☰☰☰☰☰ "
}

function _remove_all() {
    echo " "
    echo " ↪ ☰☰☰☰☰☰☰☰☰☰ -- REMOVING PACKAGES -- ☰☰☰☰☰☰☰☰☰☰"
    dpkg -r "openvas-smb"
    echo " ✔ - openvas-smb removed"
    dpkg -r "openvas-libraries"
    echo " ✔ - libraries removed"
    dpkg -r "openvas-scanner"
    echo " ✔ - openvas-scanner removed"
    dpkg -r "openvas-manager"
    echo " ✔ - openvas-manager removed"
    dpkg -r "openvas-cli"
    echo " ✔ - openvas-cli removed"
    dpkg -r "greenbone-security-assistant"
    echo " ✔ - greenbone-security-assistant removed"
}

function _start_configuration() {
  echo " "
  echo " ↪ ☰☰☰☰☰☰☰☰☰☰ -- CONFIGURATION -- ☰☰☰☰☰☰☰☰☰☰"
  cp /etc/redis/redis.conf /etc/redis/redis.orig
  echo " ✔ - redis.conf backup complete"
  echo "unixsocket /tmp/redis.sock" >> /etc/redis/redis.conf
  echo " ✔ - redis set to use unixsocket"
  echo "unixsocketperm 700" >> /etc/redis/redis.conf
  echo " ✔ - permissions for unixsocket set"
  ln -s /var/run/redis/redis.sock /tmp/redis.sock
  service redis-server restart
  openvas-manage-certs -a
  echo " ✔ - certificates ready"
  ldconfig
  echo " ✔ - ldconfig done"
}

function _create_user() {
  echo " "
  echo " ↪ ☰☰☰☰☰☰☰☰☰☰ -- CREATE USER -- ☰☰☰☰☰☰☰☰☰☰ "
  echo " ↪ Whats the name of the new user? "
  read name
  openvasmd --create-user=$name --role=Admin
  echo "↪ Set new password for $name: "
  read pw
  openvasmd --user=$name --new-password=$pw
  
}

function _update_base() {
  echo " "
  echo " ↪ ☰☰☰☰☰☰☰☰☰☰ -- UPDATING DATA -- ☰☰☰☰☰☰☰☰☰☰ "
  /usr/local/sbin/greenbone-nvt-sync
  echo " ✔ - nvt sync done"
  /usr/local/sbin/greenbone-scapdata-sync
  echo " ✔ - scapdata sync done"
  /usr/local/sbin/greenbone-certdata-sync
  echo " ✔ - certdata sync done"
}

function _killing_services() {
  echo " "
  echo " ↪ ☰☰☰☰☰☰☰☰☰☰ -- KILLING PROCESSES -- ☰☰☰☰☰☰☰☰☰☰ "
  ps aux | egrep "(openvas|gsad|redis-server)" | awk '{print $2}' | xargs -i kill -9 '{}'
  echo " ✔ openvas killed"
  echo " ✔ gsad killed"
  service redis-server stop
  echo " ✔ redis killed"
}

function _rebuild() {
  echo " "
  echo " ↪ ☰☰☰☰☰☰☰☰☰☰ -- REBUILDING NVT -- ☰☰☰☰☰☰☰☰☰☰"
  /usr/local/sbin/openvasmd --rebuild --progress
  #/usr/local/sbin/openvasmd
  #echo " ✔ start openvasmd"
  /usr/local/sbin/gsad --http-only
  echo " ✔ - set --http-only"
}

function _launch_services() {
  echo " "
  echo " ↪ ☰☰☰☰☰☰☰☰☰☰ -- LAUNCHING SERVICES -- ☰☰☰☰☰☰☰☰☰☰"
  redis-server /etc/redis/redis.conf
  echo " ✔ - config for redis-server reloaded"
  /etc/init.d/redis-server start
  echo " ✔ - redis-server started"
  /usr/local/sbin/openvasmd
  echo " ✔ - openvasmd started"
  /usr/local/sbin/openvassd
  echo " ✔ - openvassd started"
  /usr/local/sbin/gsad
  echo " ✔ - gsad started"
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
                echo "	--rebuild  : Rebuild NVT's and cache"
                echo "	--start  : Launch OpenVAS9"
                echo "	--remove  : Remove all packages"                
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



