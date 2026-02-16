#!/bin/bash
#Autosuricata install script
#Tested on Ubuntu 18.04 and 20.04
#But in theory, /should/ work for deb-based distros.

#Functions, functions everywhere.

# Logging setup. Ganked this entirely from stack overflow. Uses FIFO/pipe magic to log all the output of the script to a file. Also capable of accepting redirects/appends to the file for logging compiler stuff (configure, make and make install) to a log file instead of losing it on a screen buffer. This gives the user cleaner output, while logging everything in the background, for troubleshooting, analysis, or sending it to me for help.

logfile=/var/log/autosuricata_install.log
mkfifo ${logfile}.pipe
tee < ${logfile}.pipe $logfile &
exec &> ${logfile}.pipe
rm ${logfile}.pipe

########################################

#metasploit-like print statements. Gratuitously ganked from  Darkoperator's metasploit install script. status messages, error messages, good status returns. I added in a notification print for areas users should definitely pay attention to.

function print_status ()
{
    echo -e "\x1B[01;34m[*]\x1B[0m $1"
}

function print_good ()
{
    echo -e "\x1B[01;32m[*]\x1B[0m $1"
}

function print_error ()
{
    echo -e "\x1B[01;31m[*]\x1B[0m $1"
}

function print_notification ()
{
	echo -e "\x1B[01;33m[*]\x1B[0m $1"
}
########################################

#Script does a lot of error checking. Decided to insert an error check function. If a task performed returns a non zero status code, something very likely went wrong.

function error_check
{

if [ $? -eq 0 ]; then
	print_good "$1 successfully completed."
else
	print_error "$1 failed. Please check $logfile for more details, or contact deusexmachina667 at gmail dot com for more assistance."
exit 1
fi

}
########################################
#Package installation function.

function install_packages()
{

apt-get update &>> $logfile && apt-get install -y ${@} &>> $logfile
error_check 'Package installation'

}

########################################

#This script creates a lot of directories by default. This is a function that checks if a directory already exists and if it doesn't creates the directory (including parent dirs if they're missing).

function dir_check()
{

if [ ! -d $1 ]; then
	print_notification "$1 does not exist. Creating.."
	mkdir -p $1
else
	print_notification "$1 already exists."
fi

}

########################################
#This is a nice retry function by sj26 on github.
#link to original: https://gist.github.com/sj26/88e1c6584397bb7c13bd11108a579746
# Retry a command up to a specific numer of times until it exits successfully
function retry 
{
	local retries=$1
	shift
	local count=0
	until "$@"; do
		exit=$?
		count=$(($count + 1))
		if [ $count -lt $retries ]; then
			print_notification "Retry $count/$retries exited $exit, retrying.."
		else
			print_error "Retry $count/$retries exited with error code $exit, no more retries left."
		return $exit
		fi
	done
	return 0
}

########################################
##BEGIN MAIN SCRIPT##

#Pre checks: These are a couple of basic sanity checks the script does before proceeding.

########################################

#These lines establish where autosuricata was executed. The config file _should_ be in this directory. the script exits if the config isn't in the same directory as the autosuricata-ubuntu shell script.

print_status "Checking for config file.."
execdir=`pwd`
if [ ! -f "$execdir"/full_autosuricata.conf ]; then
	print_error "full_autosuricata.conf was NOT found in $execdir. The script relies HEAVILY on this config file. Please make sure it is in the same directory you are executing the autosuricata-ubuntu script from!"
	exit 1
else
	print_good "Found config file."
fi

source "$execdir"/full_autosuricata.conf

########################################

print_status "Checking for root privs.."
if [ $(whoami) != "root" ]; then
	print_error "This script must be ran with sudo or root privileges."
	exit 1
else
	print_good "We are root."
fi
	 
########################################	 

#this is a nice little hack I found in stack exchange to suppress messages during package installation.
export DEBIAN_FRONTEND=noninteractive

# System updates
print_status "Performing apt-get update and upgrade (May take a while if this is a fresh install).."
apt-get update &>> $logfile && apt-get -y upgrade &>> $logfile
error_check 'System updates'

########################################

#Need to do an OS version check.

print_status "OS Version Check.."
release=`lsb_release -r|awk '{print $2}'`

########################################

#These packages are recommended to build suricata to support most of its features. I also included libhyperscan-dev to enable hyperscan support.

if [[ $release == "22."* || "24."* ]]; then
	print_status "Installing Recommended Packages: autoconf automake bison build-essential ccache clang cmake curl ethtool flex gettext git gosu jq libboost-all-dev libbpf-dev libcap-ng0 libcap-ng-dev libelf-dev libevent-dev libgeoip-dev libmaxminddb-dev libhiredis-dev libjansson-dev libjson-c-dev liblua5.1-dev libluajit-5.1-dev liblz4-dev liblzma-dev libmagic-dev libnet1-dev libnuma-dev libpcap-dev libpcre2-dev libsqlite3-dev librrd-dev libtool libyaml-0-2 libyaml-dev m4 make meson pkg-config pip python3 python3-dev python3-pyelftools python3-yaml ragel sudo zlib1g zlib1g-dev.."

	declare -a packages=( autoconf automake bison build-essential ccache clang cmake curl ethtool flex gettext git gosu jq libboost-all-dev libbpf-dev libcap-ng0 libcap-ng-dev libelf-dev libevent-dev libgeoip-dev libmaxminddb-dev libhiredis-dev libjansson-dev libjson-c-dev liblua5.1-dev libluajit-5.1-dev liblz4-dev liblzma-dev libmagic-dev libnet1-dev libnuma-dev libpcap-dev libpcre2-dev libsqlite3-dev librrd-dev libtool libyaml-0-2 libyaml-dev m4 make meson pkg-config pip python3 python3-dev python3-pyelftools python3-yaml ragel sudo zlib1g zlib1g-dev );
	
	install_packages ${packages[@]}
else
	print_notification "This script has only been tested with Ubuntu 22.04+. It may work on other .deb-based distros, it may not. YMMV. Please report failures as github issues."
	print_status "Attempting to Install Recommended Packages: autoconf automake bison build-essential ccache clang cmake curl ethtool flex gettext git gosu jq libboost-all-dev libbpf-dev libcap-ng0 libcap-ng-dev libelf-dev libevent-dev libgeoip-dev libmaxminddb-dev libhiredis-dev libjansson-dev libjson-c-dev liblua5.1-dev libluajit-5.1-dev liblz4-dev liblzma-dev libmagic-dev libnet1-dev libnuma-dev libpcap-dev libpcre2-dev libsqlite3-dev librrd-dev libtool libyaml-0-2 libyaml-dev m4 make meson pkg-config pip python3 python3-dev python3-pyelftools python3-yaml ragel sudo zlib1g zlib1g-dev.."

	declare -a packages=( autoconf automake bison build-essential ccache clang cmake curl ethtool flex gettext git gosu jq libboost-all-dev libbpf-dev libcap-ng0 libcap-ng-dev libelf-dev libevent-dev libgeoip-dev libmaxminddb-dev libhiredis-dev libjansson-dev libjson-c-dev liblua5.1-dev libluajit-5.1-dev liblz4-dev liblzma-dev libmagic-dev libnet1-dev libnuma-dev libpcap-dev libpcre2-dev libsqlite3-dev librrd-dev libtool libyaml-0-2 libyaml-dev m4 make meson pkg-config pip python3 python3-dev python3-pyelftools python3-yaml ragel sudo zlib1g zlib1g-dev );
	
	install_packages ${packages[@]}
fi



########################################
#currently there are no rustc or cargo packages available on 18.04 and according to the rust language webpage, the language is subject to rapid change. So, we're going to install rustc and cargo through the rust-init shell script, instead of relying on the package manager.
print_status "Installing rust via rust-init.."
cd /usr/src
curl https://sh.rustup.rs -sSf | sh -s -- -y  &>> $logfile
error_check 'Install of rustc and cargo'

#per the rust-init script, in order to actually use rust, We have to add Cargo to the PATH variable.
source /root/.cargo/env
error_check 'Adding Cargo bin directory to PATH variable'

########################################
#Suricata docs recommend installing rust's cbindgen crate, so we're gonna do that.
print_status "Installing cbindgen.."
cargo install --force --debug cbindgen &>> $logfile
error_check 'Installation of cbindgen'

########################################
#downloading, compiling and installing libpcre v 8.45 for vectorscan

print_status "Downloading, compiling, and installing libpcre-8.45.."

cd /usr/src &>> $logfile
retry 3 wget https://sourceforge.net/projects/pcre/files/pcre/8.45/pcre-8.45.tar.gz/download -O pcre-8.45.tar.gz &>> $logfile
error_check "Download of vectorscan libpcre-8.45"

tar -xzvf pcre-8.45.tar.gz &>> $logfile
error_check 'Untar of libpcre-8.45 sources'

cd pcre-8.45/ &>> $logfile

./configure &>> $logfile
error_check 'configure of libpcre-8.45 sources'

make -j $(nproc) &>> $logfile
error_check 'make of libpcre-8.45 sources'

make install &>> $logfile
error_check 'make install of libpcre-8.45 sources'

#installing vectorscan
#vectorscan is the supported drop-in replacement for hyperscan, since Intel just kinda pulled the plug on the open-source version..

print_status "Downloading, compiling, and installing vectorscan.."

cd /usr/src &>> $logfile

#if the vectorscan library already exists, git clone fails. So we remove it, if it exists.
if [ -d /usr/src/vectorscan ]; then
	rm -rf /usr/src/vectorscan
fi

git clone https://github.com/VectorCamp/vectorscan &>> $logfile
error_check "Download of vectorscan repo"

cd /usr/src/vectorscan &>> $logfile
dir_check vectorscan-build
cd /usr/src/vectorscan/vectorscan-build &>> $logfile
cmake -DBUILD_SHARED_LIBS=On ../ &>> $logfile
error_check "CMake of vectorscan"

make -j $(nproc) &>> $logfile
error_check 'Make vectorscan'

make install &>> $logfile
error_check 'Installation of vectorscan'
ldconfig

########################################
#If users want dpdk support, then we need to acquire dpdk sources and build them. The builds for meson and ninja _shouldn't_ fail, but if they do, exit the script.
if [[ $dpdk_support == "yes" ]]; then

	print_status 'Downloading and installing DPDK..'
	retry 3 wget http://fast.dpdk.org/rel/dpdk-25.11.tar.xz &>> $logfile
	error_check 'Download of DPDK sources'
	print_notification 'If this task failed, please check your network connection and/or submit a github issue for me to check for a new LTS build'
	
	tar -xJvf dpdk-25.11.tar.xz &>> $logfile
	error_check 'Untar of DPDK sources'
	
	cd dpdk-25.11 &>> $logfile
	
	print_status 'Attempting meson and ninja builds for DPDK sources..'
	print_notification 'If either of these tasks fail, and the autosuricata_install.log is NOT helpful, consider changing the dpdk_support variable in full_autosuricata.conf to dpdk_support=no'
	
	meson setup build &>> $logfile
	error_check 'DPDK meson build'
	
	print_status 'Performing ninja build for DPDK sources..'
	cd build
	print_notification 'This may take a moment or two. To view progress, consider opening another terminal window and running tail -f /var/log/autosuricata.log'
	ninja -j $(nproc) &>> $logfile
	error_check 'DPDK ninja build'
	meson install &>> $logfile
	error_check 'DPDK meson install'
	ldconfig
	cd /usr/src
fi

########################################
#If users want nDPI support, then we need to acquire nDPI sources and build them.
#Currently pulling down nDPI 4.10, because later releases aren't supported because of some API changes.
#There's a territorial dispute as to whose problem it is right now to fix it, so until then, we're just grabbing 4.10 and calling it a day.
if [[ $nDPI_support == "yes" ]]; then
    #neat one-liner for pulling the latest build from github, then feeding that into a wget command.
	# saving for later. 5.0 makes API changes and isn't yet supported by suricata.
    #ndpi_latest=`curl -s https://api.github.com/repos/ntop/nDPI/releases | grep "tarball_url." | head -1 | cut -d : -f 2,3 | cut -d \" -f2`
    print_status 'Downloading and installing nDPI..'
	# saving for later when support for ndpi 5.0 is fixed.
	#retry 3 wget $ndpi_latest -O nDPI_latest.tar.gz &>> $logfile
	retry 3 wget https://github.com/ntop/nDPI/archive/refs/tags/4.14.tar.gz -O nDPI_4.14.tar.gz &>> $logfile
	tar -xzvf nDPI_4.14.tar.gz &>> $logfile
	cd nDPI-4.14
	./autogen.sh &>> $logfile
	./configure &>> $logfile
	make -j &>> $logfile
	error_check 'nDPI compile'
	cd /usr/src
fi

########################################
#Download, unpack, compile, and install Suricata. make install-full installs the ET ruleset alongside suricata as well.
print_status "Acquiring and unpacking suricata-current.tar.gz to /usr/src.."

retry 3 wget http://www.openinfosecfoundation.org/download/suricata-current.tar.gz &>> $logfile
error_check 'Download of Suricata'

tar -xzvf suricata-current.tar.gz &>> $logfile
error_check 'Untar of Suricata'

suricata_ver=`ls -1 | egrep "suricata-[0-9]" | head -1`

cd $suricata_ver

print_status "Configuring suricata, making and installing. This will take a moment or two.."
#Attempe to configure Suricata, with the options the user wants. If that configure state fails, then the script bails, instead of trying to compile without the requested features.
#Make it a choice of the user, instead of assuming they want to continue without their desired features.
#Option 1: with DPDK and nDPI (default)
if [[ $dpdk_support == "yes" && $nDPI_support == "yes" ]]; then
    print_status 'Attempting build with DPDK and nDPI support..'
	./configure --enable-lua --enable-geoip --enable-hiredis --enable-dpdk --enable-ndpi --with-ndpi=/usr/src/nDPI-4.14 &>> $logfile
	error_check 'Configure Suricata with DPDK and nDPI support'
fi
#Option 2: without DPDK
if [[ $dpdk_support != "yes" && $nDPI_support == "yes" ]]; then
    print_status 'Attempting build with nDPI support (no DPDK)..'
	./configure --enable-lua --enable-geoip --enable-hiredis --enable-ndpi --with-ndpi=/usr/src/nDPI-4.14 &>> $logfile
	error_check 'Configure Suricata with nDPI support (no DPDK)'
fi
# Option 3: without nDPI
if [[ $dpdk_support == "yes" && $nDPI_support != "yes" ]]; then
    print_status 'Attempting build with DPDK support (no nDPI)..'
	./configure --enable-lua --enable-geoip --enable-hiredis --enable-dpdk &>> $logfile
	error_check 'Configure Suricata with DPDK support (no nDPI)'
fi
#Option 4: without nDPI or DPDK
if [[ $dpdk_support != "yes" && $nDPI_support != "yes" ]]; then
    print_status 'Attempting build without DPDK or nDPI support..'
	./configure --enable-lua --enable-geoip --enable-hiredis &>> $logfile
	error_check 'Configure Suricata wihtout DPDK or nDPI support'
fi

make -j $(nproc) &>> $logfile
error_check 'Make Suricata'

make install-full &>> $logfile
error_check 'Installation of Suricata'

#need to run ldconfig, because in spite of make install-full successfully running now, suricata will fail to run on next boot because it still doesn't know that libhtp.so exists.
ldconfig &>> $logfile

print_notification "Suricata has been installed to: /usr/local/bin/suricata"
print_notification "YAML located at: /usr/local/etc/suricata/suricata.yaml"
print_notification "Rules located at: /usr/local/var/lib/suricata/rules"

print_status "Changing default log directory to /var/log/suricata.."
sed -i "s#default-log-dir: /usr/local/var/log/suricata/#default-log-dir: /var/log/suricata/#" /usr/local/etc/suricata/suricata.yaml

dir_check /var/log/suricata

print_status "Checking for suricata user and group.."

getent passwd suricata &>> $logfile
if [ $? -eq 0 ]; then
	print_notification "suricata user exists. Verifying group exists.."
	id -g suricata &>> $logfile
	if [ $? -eq 0 ]; then
		print_notification "suricata group exists."
	else
		print_notification "suricata group does not exist. Creating.."
		groupadd suricata
		usermod -G suricata suricata
	fi
else
	print_status "Creating suricata user and group.."
	groupadd suricata
	useradd -g suricata suricata -s /bin/false	
fi

print_status "Tightening permissions to /var/log/suricata.."
chmod 5775 /var/log/suricata
chown suricata:suricata /var/log/suricata

########################################

#GRO and LRO are checksum offloading techniques that some network cards use to offload checking frame, packet and/or tcp header checksums and can lead to invalid checksums. Suricata doesn't like packets with invalid checksums and will ignore them. These commands disable GRO and LRO.

print_notification "Disabling offloading options on the sniffing interfaces.."
ethtool -K $suricata_iface_1 rx off &>> $logfile
ethtool -K $suricata_iface_1 tx off &>> $logfile
ethtool -K $suricata_iface_1 sg off &>> $logfile
ethtool -K $suricata_iface_1 tso off &>> $logfile
ethtool -K $suricata_iface_1 ufo off &>> $logfile
ethtool -K $suricata_iface_1 gso off &>> $logfile
ethtool -K $suricata_iface_1 gro off &>> $logfile
ethtool -K $suricata_iface_1 lro off &>> $logfile
ethtool -K $suricata_iface_2 rx off &>> $logfile
ethtool -K $suricata_iface_2 tx off &>> $logfile
ethtool -K $suricata_iface_2 sg off &>> $logfile
ethtool -K $suricata_iface_2 tso off &>> $logfile
ethtool -K $suricata_iface_2 ufo off &>> $logfile
ethtool -K $suricata_iface_2 gso off &>> $logfile
ethtool -K $suricata_iface_2 gro off &>> $logfile
ethtool -K $suricata_iface_2 lro off &>> $logfile 

########################################

#suricata.yaml needs to be reconfigured to support af-packet inline mode operation. the af-packet config needs to be fully commented out.

print_status "disabling default af-packet configuration in suricata.yaml.."

sed -i "s/af-packet:/#af-packet:/" /usr/local/etc/suricata/suricata.yaml &>> $logfile
sed -i "s/- interface: eth0/#- interface: eth0/" /usr/local/etc/suricata/suricata.yaml &>> $logfile
sed -i "s/cluster-id: 99/#cluster-id: 99/" /usr/local/etc/suricata/suricata.yaml &>> $logfile
sed -i "s/cluster-type: cluster_flow/#cluster-type: cluster_flow/" /usr/local/etc/suricata/suricata.yaml &>> $logfile
sed -i "s/defrag: yes/#defrag: yes/" /usr/local/etc/suricata/suricata.yaml &>> $logfile
sed -i "s/- interface: default/#- interface: default/" /usr/local/etc/suricata/suricata.yaml &>> $logfile

print_good "default afpacket configuration commented out"

########################################

#Suricata systemd service script, suricatad installation/configuration.

print_status "Setting up suricatad systemd service script.."

cd "$execdir"
if [ -f /etc/systemd/system/suricatad.service ]; then
	print_notification "Suricata systemd service script already installed."
else
	if [ ! -f "$execdir"/suricatad.service ]; then
		print_error" Unable to find $execdir/suricatad.service. Please ensure the suricatad.service file is there and try again."
		exit 1
	else
		print_good "Found suricatad systemd service script. Configuring.."
	fi
	
	cp suricatad.service suricatad_2 &>> $logfile
	sed -i "s#suricata_iface1#$suricata_iface_1#g" suricatad_2
	sed -i "s#suricata_iface2#$suricata_iface_2#g" suricatad_2
	cp suricatad_2 /etc/systemd/system/suricatad.service &>> $logfile
	chown root:root /etc/systemd/system/suricatad.service &>> $logfile
	chmod 600 /etc/systemd/system/suricatad.service &>> $logfile
	systemctl daemon-reload &>> $logfile
	error_check 'suricatad.service installation'
	print_notification "Location: /etc/systemd/system/suricatad.service"
	systemctl enable suricatad.service &>> $logfile
	error_check 'suricatad.service enable'	
	rm -rf suricatad_2 &>> $logfile
fi

########################################

#have to configure and include af-packet.yaml for inline mode operation.
print_status "Setting up af-packet.yaml.."

cd "$execdir"
if [ -f /usr/local/etc/suricata/af-packet.yaml ]; then
	print_notification "af-packet.yaml already installed."
else
	if [ ! -f "$execdir"/af-packet.yaml ]; then
		print_error" Unable to find $execdir/af-packet.yaml. Please ensure the af-packet.yaml file is there and try again."
		exit 1
	else
		print_good "Found af-packet.yaml script."
	fi
	
	cp af-packet.yaml af-packet.yaml_2 &>> $logfile
	sed -i "s#suricata_iface1#$suricata_iface_1#g" af-packet.yaml_2 &>> $logfile
	sed -i "s#suricata_iface2#$suricata_iface_2#g" af-packet.yaml_2 &>> $logfile
	cp af-packet.yaml_2 /usr/local/etc/suricata/af-packet.yaml &>> $logfile
	print_notification "af-packet.yaml placed in /usr/local/etc/suricata"
	echo "include: af-packet.yaml" >> /usr/local/etc/suricata/suricata.yaml
	rm -rf afpacket.yaml_2 &>> $logfile
fi

########################################
#We need to set permissions of everything in these directories to the suricata user/group, otherwise the daemon can't read any config files, rule files, or lay down control sockets. We tell the users that they may need to change file permissions for the config files and/or rules after runnig suricata-update

print_status "modifying permissions to allow the suricata user and group access to rules, config files, etc."

dir_check /usr/local/var/run/suricata

chown -R suricata:suricata /usr/local/var/lib/suricata
error_check 'suricata user ownership of /usr/local/var/lib/suricata'
chown -R suricata:suricata /usr/local/etc/suricata
error_check 'suricata user ownership of /usr/local/etc/suricata'
chown -R suricata:suricata /usr/local/var/run/suricata

########################################

print_status "Rebooting now.."
init 6
print_notification "The log file for autosuricata is located at: $logfile"
print_notification "Wanna update your rules? run suricata-update -D /usr/local/etc/suricata --no-merge"
print_notification "You want also want to run chown -R suricata:suricata /usr/local/etc/suricata, AND chown -R suricata:suricata /usr/local/var/lib/suricata/ AFTER doing this"
print_good "We're all done here. Have a nice day."

exit 0