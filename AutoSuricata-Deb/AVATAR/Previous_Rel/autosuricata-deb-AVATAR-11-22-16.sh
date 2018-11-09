#!/bin/bash
#Autosuricata install script
#Tested on Ubuntu 16.04.1
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
if [[ $release == "16."* || "18."* ]]; then
	print_good "OS is Ubuntu. Good to go."
else
    print_notification "This is not Ubuntu 16.x or 18.x, this script has NOT been tested on other platforms."
	print_notification "You continue at your own risk!(Please report your successes or failures!)"
fi

########################################

#These packages are required at a minimum to build snort and barnyard + their component libraries. The perl requirements are for pulledpork.pl
#A package name changed on Ubuntu 18.04, and we need to account for that. so we do an if/then based on the release we pulled a moment ago.

if [[ $release == "18."* ]]; then
	print_status "Installing base packages: libpcre3 libpcre3-dbg libpcre3-dev build-essential autoconf automake libtool libpcap-dev libnet1-dev libyaml-0-2 libyaml-dev zlib1g zlib1g-dev libcap-ng-dev libcap-ng0 make libmagic-dev libjansson-dev libjansson4 pkg-config libarchive-tar-perl libnet-ssleay-perl libwww-perl.."
	
	declare -a packages=( libpcre3 libpcre3-dbg libpcre3-dev build-essential autoconf automake libtool libpcap-dev libnet1-dev libyaml-0-2 libyaml-dev zlib1g zlib1g-dev libcap-ng-dev libcap-ng0 make libmagic-dev libjansson-dev libjansson4 pkg-config libarchive-tar-perl libnet-ssleay-perl libwww-perl );
	
	install_packages ${packages[@]}
else
	print_status "Installing base packages: libpcre3 libpcre3-dbg libpcre3-dev build-essential autoconf automake libtool libpcap-dev libnet1-dev libyaml-0-2 libyaml-dev zlib1g zlib1g-dev libcap-ng-dev libcap-ng0 make libmagic-dev libjansson-dev libjansson4 pkg-config libarchive-tar-perl libcrypt-ssleay-perl libwww-perl.."
	
	declare -a packages=( libpcre3 libpcre3-dbg libpcre3-dev build-essential autoconf automake libtool libpcap-dev libnet1-dev libyaml-0-2 libyaml-dev zlib1g zlib1g-dev libcap-ng-dev libcap-ng0 make libmagic-dev libjansson-dev libjansson4 pkg-config libarchive-tar-perl libcrypt-ssleay-perl libwww-perl );
	
	install_packages ${packages[@]}
fi

########################################
#Download, unpack, compile, and install Suricata. make install-full installs the ET ruleset alongside suricata as well.
print_status "Acquiring and unpacking suricata-current.tar.gz to /usr/src.."

wget http://downloads.suricata-ids.org/suricata-current.tar.gz &>> $logfile
error_check 'Download of Suricata'

tar -xzvf suricata-current.tar.gz &>> $logfile
error_check 'Untar of Suricata'

suricata_ver=`ls -1 | egrep "suricata-[0-9]"`

cd $suricata_ver

print_status "configuring suricata, making and installing. This will take a moment or two."

./configure &>> $logfile
error_check 'Configure Suricata'

make &>> $logfile
error_check 'Make Suricata'

make install-full &>> $logfile
error_check 'Installation of Suricata'

#this MUST be ran otherwise you get the error: suricata: error while loading shared libraries: libhtp-0.5.23.so.1: cannot open shared object file: No such file or directory
ldconfig

print_notification "Suricata has been installed to: /usr/local/bin/suricata"
print_notification "YAML located at: /usr/local/etc/suricata/suricata.yaml"
print_notification "Rules located at: /usr/local/etc/suricata/rules/"

print_status "Changing default log directory to /var/log/suricata.."
sed -i "s#default-log-dir: /usr/local/var/log/suricata/#default-log-dir: /var/log/suricata/#" /usr/local/etc/suricata/suricata.yaml

dir_check /var/log/suricata

########################################

#Pulled Pork. Download, unpack, and configure.

cd /usr/src

if [ -d /usr/src/pulledpork ]; then
	rm -rf /usr/src/pulledpork
fi

print_status "Acquiring Pulled Pork.."

git clone https://github.com/shirkdog/pulledpork.git &>> $logfile
error_check 'Download of pulledpork'

print_good "Pulledpork successfully installed to /usr/src."

print_status "Generating pulledpork.conf.."

cd pulledpork/etc

#Create a copy of the original conf file (in case the user needs it). If the user supplied an oink code, we can assume that they want to use the ET PRO ruleset. Otherwise, we assume they want to use the free rules.
cp pulledpork.conf pulledpork.conf.orig

if [ -z "$o_code" ]; then
	echo "rule_url=https://rules.emergingthreats.net/open-nogpl/suricata/|emerging.rules.tar.gz|open-nogpl" >> pulledpork.tmp
else
	#I'm not able to validate that this is a correct rule_url at this time
	#I don't have an ETPRO subscription.
	echo "rule_url=https://rules.emergingthreatspro.com/|etpro.rules.tar.gz|$o_code" > pulledpork.tmp
fi


echo "ignore=deleted.rules,experimental.rules,local.rules" >> pulledpork.tmp
echo "temp_path=/tmp" >> pulledpork.tmp
echo "out_path=/usr/local/etc/suricata/rules/" >> pulledpork.tmp
echo "local_rules=/usr/local/etc/suricata/rules/local.rules" >> pulledpork.tmp
echo "sid_msg=/usr/local/etc/suricata/rules/sid-msg.map" >> pulledpork.tmp
echo "sid_msg_version=2" >> pulledpork.tmp
echo "sid_changelog=/var/log/sid_changes.log" >> pulledpork.tmp
echo "snort_path=/usr/local/bin/suricata" >> pulledpork.tmp
echo "config_path=/usr/local/etc/suricata.yaml" >> pulledpork.tmp
echo "version=0.7.3" >> pulledpork.tmp
cp pulledpork.tmp pulledpork.conf

print_good "pulledpork.conf generated."
print_notification "pulledpork has NOT been ran, because make install-full installs the et-nogpl ruleset by default."

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

#Suricata init script, suricatad installation/configuration.

print_status "Setting up suricatad init script.."

cd "$execdir"
if [ -f /etc/init.d/suricatad ]; then
	print_notification "Suricatad init script already installed."
else
	if [ ! -f "$execdir"/suricatad ]; then
		print_error" Unable to find $execdir/suricatad. Please ensure suricatad file is there and try again."
		exit 1
	else
		print_good "Found suricatad init script."
	fi
	
	cp suricatad suricatad_2 &>> $logfile
	sed -i "s#suricata_iface1#$suricata_iface_1#g" suricatad_2 &>> $logfile
	sed -i "s#suricata_iface2#$suricata_iface_2#g" suricatad_2 &>> $logfile
	cp suricatad_2 /etc/init.d/suricatad &>> $logfile
	chown root:root /etc/init.d/suricatad &>> $logfile
	chmod 700 /etc/init.d/suricatad &>> $logfile
	update-rc.d suricatad defaults &>> $logfile
	error_check 'Init Script installation'
	print_notification "Init script located in /etc/init.d/suricatad"
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

print_status "Rebooting now.."
init 6
print_notification "The log file for autosuricata is located at: $logfile" 
print_good "We're all done here. Have a nice day."

exit 0