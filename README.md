# openvas_installation_script

simple installer script for OpenVAS9

## Compatibility

script has been tested on Ubuntu 16.04.x and Ubuntu Server 16.04.5

## How-to

1. Download script file
2. chmod +x _ovas9_installer.sh
3. sudo -s
4. Run the following commands to install OpenVAS9 from source <./_ovas9_installer.sh OPTION>:
  * --install-pre: Will download needed packages to install and run OpenVAS9
  * --get-src: Will download and unzip all packages necessary for installation (to avoid compatibility issues do not download other versions)
  * --install-src: install downloaded packages. This will create a source folder within each package to run cmake/make/make install
  * --configure: change config of redis-server to use unixsocket
  * --create-usr: specify name and pw
  * --update: update nvt's and data
  * --kill-services 
  * --start
  * --rebuild
