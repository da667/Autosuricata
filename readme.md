# Autosuricata - The meerkat's mastery
## What is Autosuricata?
Autosuricata is a shell script that Automates the task of building Suricata from source.

This script is primarily for students attempting to build Suricata for my book, Building Virtual Machine Labs: A Hands-On Guide (Second Edition), and/or the very soon to be announced updated Applied Network Defense training, bearing the same name.

I'll get into the details of what this script does in a little bit.

## Supported Operating Systems
As of right now, Autosuricata is supported on Ubuntu 20.04 and 18.04. This script is entirely built off of Suricata's read the docs documentation and recommendations.

https://suricata.readthedocs.io


## Prerequisites
**System Resource Recommendations:** at a minimum, I recommend a system with at least:

 - [ ] 1 CPU core
 - [ ] 4GB of RAM
 - [ ] 80GB of disk space
 - [ ] 3 network interfaces (one for management traffic, two for inline operation)

These are the specs for the VM I used to test this script. As with most software, the more resources it has available, the better it will perform. Suricata has always been multi-threaded, so more CPU cores is never a bad thing.

**OS Recommendations:** This script has been tested on Ubuntu 20.04 and 18.04. If you want to use another Debian-based distro, be my guest. *However* that is entirely unsupported and untested.

**Other Recommendations:** 

**This script takes a significant period of time to run.** Suricata will take a little bit of time to compile. If you're using the minimum system requirements, you'll need at least 30+ minutes for it to compile and configure everything. That's also assuming a moderately decent internet connection required to download everything.

**This script defaults to assuming you want to run Suricata in inline mode.** If you don't want that, I'll show you how to undo that in a little bit.

## What does this script do *exactly*?
AutoSuricata automates all of the following tasks:
 - Installs all of the prerequisites available from the Ubuntu repositories for Suricata
 - Installs the latest build of Suricata
	- Creates the `suricata` system user and group in order for the suricata process to drop its privileges after startup
	- Configures Suricata for inline operation through the included `af-packet.yaml` file.
	- Configures Suricata to log to `/var/log/suricata`
	- Installs, configures and runs `suricata-update`, a rule download and configuration management script for Suricata.
		- `suricata-update` will download a default set of rules from the ETOPEN ruleset for use in network inspection.
		- Please note that `suricata-update` is run with its default settings. example configuration files are available in `/usr/src/suricata-6.0.4/suricata-update/suricata/update/configs`, and will need to be created or moved to `/etc/suricata` in order for suricata-update to do anything with your customizations.
		- For more documentation on `suricata-update`, please visit: https://github.com/OISF/suricata-update
	- Installs `suricatad.service` that performs the following tasks:
		- Enables service persistence for Suricata, and will also try to re-start the service if the main suricata process dies.
		- runs `ethtool` on service startup against both network interfaces defined in `full_autosuricata.conf` to disable both the LRO and GRO settings
		- runs `ip link` against both network interfaces defined in `full_autosuricata.conf`, configuring them to: 
			- ignore arp requests
			- ignore multicast requests
			- run in promiscuous mode.
			- This effectively means that these network interfaces will listen to any and all network traffic it can see on their respective network segments, they invisibly forward traffic in inline mode
			- The interfaces will **NOT** respond to any network traffic directed specifically towards either interface
		- Runs Suricata with the following arguments:
			- `-c /usr/local/etc/suricata/suricata.yaml` (where the configuration file lives)
			- `-D` (daemonize)
			- `--user=suricata` (run as the `suricata` user and group after startup)
			- `--afpacket` (ensures that Suricata is running in AFPACKET mode
			- `-k none` (do not drop packets with bad checksums)

## Instructions for use
 1. If you are running this script behind a proxy, make sure you run your export commands to set the http_proxy and https_proxy variables.
 - e.g. `export http_proxy=172.16.1.1:3128`
 - e.g. `export https_proxy=`
 2. Clone this repo (`git clone https://github.com/da667/Autosuricata`)
 3. cd into `Autosuricata/AutoSuricata-Deb/AVATAR`
 4. using your favorite text editor, open `full_autosuricata.conf`
 5. input the names of the network interfaces you'd like to bridge together for inline mode (if you want to use inline mode) in the `suricata_iface_1=` (line 12) and `suricata_iface_2=` (line 20) fields. For example, the script defaults to the interface names `eth1` and `eth2`.
 6. the script file, `autosuricata-deb-AVATAR.sh`, needs to specifically be ran with the `bash` interpreter, and with `root` permissions.
- If you downloaded the script as the `root` user, `bash autosuricata-deb-AVATAR.sh` will work
- Alternatively, as the `root` user: `chmod u+x autosuricata-deb-AVATAR.sh && ./autosuricata-deb-AVATAR.sh`
- or via `sudo`: `sudo bash autosuricata-deb-AVATAR.sh`, etc.

That's all there is to it. Once the script starts running, you'll get status updates printed to the screen to let you know what task is currently being executed. If you want to make sure the script isn't hanging, you can run `tail -f /var/log/autosuricata_install.log` to view detailed command output.

## The script bombed on me. Wat do?
Every task the script performs gets logged to `/var/log/autosuricata_install.log`. This will *hopefully* make debugging problems with the script much easier. Take a look and see if you can figure out what caused the installer script to vomit.

## I am not interested in inline mode operation at all. Wat do?
Fun fact: the `suricata_iface_1` and `suricata_iface_2` options in `full_autosuricata.conf` aren't technically required. If you leave these fields blank, or their default values (assuming you don't have an `eth1` or `eth2` interface) the script will still finish. However, there are a couple of minor things you'll need to fix:
- Either modify or remove `/etc/systemd/system/suricatad.service` . 
	- To remove the service file entirely, run:
		- `systemctl disable suricatad.service`
		- `rm -rf /etc/systemd/system/suricatad.service`
	- To modify the file for passive operation, perform the following actions:
		- To stop inline mode operation, the `-afpacket` option will need to be removed from the suricata command (line 18 `suricatad.service`). 
		- after removing `-afpacket`, Add the `-i [interface_name]` command line argument to line 18 define the network interface you'd like to use for IDS mode operation.
		- On lines 14 and 16, make sure you add the interface name you defined on line 18.
			- e.g. `/usr/sbin/ip link set up promisc on arp off multicast off dev [interface name]`
			- e.g. `/usr/sbin/ethtool -K [interface name] rx off tx off gro off lro off`
		- Remove lines 15 and 17.
- Either modify or remove the file `/usr/local/etc/suricata/af-packet.yaml`
	- to remove the file,  run `rm -rf /usr/local/etc/suricata/af-packet.yaml`
		- You'll also need to remove the `include: af-packet.yaml` statement at the very end of the `/usr/local/etc/suricata/suricata.yaml` file.

## Licensing

This script is released under the MIT license. There is no warranty for this software, implied or otherwise.

## Acknowledgements

A big thanks to @inliniac and the rest of the OISF dev team for being so approachable, and writing good, accessible documentation.
		
## Patch Notes
 -1-15-22
	-Hey Hey people! Happy new year. Some very minor changes to this release to enable a couple of extra features:
		- This script now installs libhyperscan-dev in order to provide Suricata the ability to use hyperscan for pattern matching. Suricata has had support for hyperscan for ages now, and since Autosnort3 uses it to build snort3, I would install and configure hyperscan for use with suricata as well.
		- Suricata is now compiled with support for HTTP2 decompression (`--enable-http2-decompression`). According to @inliniac, this is considered an experimental feature right now. Most people probably won't need it, but if you want to mess with it, its enabled. Likewise, if it gives you any problems or causes any stability issues, remove the line `--enable-http2-decompression` from line 209 in `autosuricata-dev-AVATAR.sh`
	-Configured suricata to run with the `-k none` argument. This means suricata will not drop traffic with bad checksums.
	-The documentation on readthedocs recommends installing rust's `cbindgen` crate, so I've updated the script to do just that.
	-Reorganized the readme file to bring it more in line with the nicely formatted readme.md that comes with autosnort3. The new readme includes better instructions, and how to reconfigure Suricata for passive mode operation, if desired.
	-Removed the previous releases directory.

 -4-25-21
	-Fixed a permissions problem with the directory, /var/log/suricata. The file permissions have changed from 770 to 5775. Why? The splunk universal forwarder needs to be able to traverse the directory to read the eve.json file, and the splunk user is considered "world" and so with 770 permissions has no rights to look at anything in the directory, even though the files contained within are configured with 644 permissions.

 -4-11-21
	-Fixed a bug in suricatad.service. Changed the service type from simple to forking in order for the PIDFile directive to handle tracking the pidfile, and removing stale pid files.

 -4-27-20
	-Ubuntu 20.04 has officially been released. In preparation for a new Building Virtual Machine Labs release, This script has been updated.
	-Support for Ubuntu 16.04 has been removed from this release. If you have a need to install suricata on Ubuntu 16.04, the previous releases directory should have what you need. Dont sweat it!
	-Tested out a couple of fixs that the OISF/Suricata dev team implemented, including a bug affecting suricata-update, and a bug affecting make install-full. Hypothetically, no longer having to work around these problems means that the installation will go a little bit faster.
	-Discovered that suricata requires libmaxminddb-dev, so added that as an install requirement. Should fix the suricata configure choking and telling people that the library isn't there.
	-There have been some changes to where and how the suricata.yaml handles rules by default.
		-Rules used to be, by default separated out into their individual categories. Apparently now, the default suricata.yaml config is to merge everything into suricata.rules.
		-I'm going to deal with this for now, and maybe include some lessons on rule management using either suricata-update, or maybe scirius for rule management.
		-rules are now located in /usr/local/var/lib/suricata/rules
	-Finally made the switch from an init script to a full-on systemd service file. After some trial and error, I think I have a service script that properly kills the suricata process and ensures that the pidfile isn't present before trying to run a new suricata process (resulting in "zombie" processes, and/or failing to start suricata due to stale pid files being present)
	-Created a suricata user and group and configured dropping the suricata daemon's privs to the suricata user, instead of letting the service run as root, in accordance to best practices for system services
	-Performed some script cleanup. Stuff like removing references to pulledpork in the main script and also in the full_autosuricata.conf file, etc.
	-Be aware that since you'll likely be running suricata-update as a user that is NOT the suricata user, suricata will likely not be able to read any new files suricata-update creates in /usr/local/var/lib/suricata or /usr/local/etc/suricata. If you check /var/log/suricata/suricata.log and its vomiting about not being able to read the suricata.rules, classification.config and/or reference config OR, you see it complaining that it couldn't create a control socket due to insufficient permissions you'll want to run the following commands:
		-chown -R suricata:suricata /usr/local/var/lib/suricata
		-chown -R suricata:suricata /usr/local/etc/suricata
		-chown -R suricata:suricata /usr/local/var/run/suricata
		-Then either reboot the system, or restart the suricatad service. Pray that it was just a file permissions problem.

 -4-26-19
	-Decided that it was time to stop installing pulledpork. Suricata has the suricata-update rule manager, and not only that, its included with the install. And is officially supported.
	-Discovered that at some point between now, and the last version of this script, that the suricata project has decided that suricata rules live elsewhere when you run make install-full than /usr/local/etc/suricata/rules. Fixed this by running suricata-update -D /usr/local/etc/suricata
	-Additionally, while doing this update, figured out that some rules that are enabled by default rely on some of the protocol-event.rules files that are shipped in the suricata source tarball. If these rules are NOT available, whenever you attempt to test your suricata config, you will get several warnings about rules that check for certain flowbits to be set, but those rules not being available. These rules do NOT get downloaded with suricata-update for reasons entirely beyond me, so to fix THAT issue:
	-the suricata source tarball is now downloaded to /usr/src
	-the protocol-event.rules (e.g. tls-events, http-events, etc.) are copied over to /usr/local/etc/suricata/rules
	-suricata-update is ran with the --no-merge flag so you can see what rule categories are enabled and have more granular control of your rules.

 -11-12-18
	-Ubuntu 18.04 users: apparently, when I tested, I didn't test things well enough. Ran into a problem where users who installed ubuntu 18.04.1 server from ISO (as opposed to doing do-release-upgrade to 18.04.1 from ubuntu 16.04.x) have a different /etc/apt/sources.list and are unable to install all of the requisite packages. Fixed this by:
		-making a backup of /etc/apt/sources.list in case users have custom repos they enabled
		-blowing away the existing sources.list and replacing with with the default repos from a fresh ubuntu 18.04 install with the "universe" repo installed in addition to the "main" repo
		-if the backup file exists, we assume its due to a failed script run and do NOT over write it (e.g. if /etc/apt/sources.list.bak exists, we do NOT overwrite it)
		-advise the user if they have custom repos configured for their apt sources.list file, to restore them from the backup file we made -- /etc/apt/sources.list.bak
	-noticed that in spite of having the libraries for a bunch of enhanced features (e.g. hiredis, geoip, and lua support), that suricata was compiling without support for any of these features. Changed the "./configure" portion of the installer to enable support for extra features. Suricata is now compiled with support for:
		-rust
		-geoip
		-hiredis
		-lua
		-liblz4
		-liblzma
	-decided that since rust is a programming language that is subject to constant updating, that using rust-init to install rustc and cargo is probably for the best, since Linux distro packages tend to lag behind. Both 18.04 and 16.04 users install rustc and cargo via rust-init now.

 -11-09-18
	-Suricata 4.1.0 came out, and with it, rust has become a dominant force in the suricata development community.
	-re-worked the dependencies that get installed, per the readthedocs documentation. Recommended dependencies, including rust dependencies are now installed.
	-suricata-update, what appears to be some sort of a rule manager for suricata, is installed. without it, make install-full fails to complete. While suricata-update is apparently the new way to manage Suricata rules, I'm opting to install pulledpork (and its dependencies) to ensure that users who are use to its syntax can keep using it.
	-python-pip installed in order to install suricata-update and pyyaml dependency
	-discovered a bug where compiling suricata with rust features fails because rust/cargo target path variable can't deal with directory paths that have spaces. This seems like an upstream bug, but I fixed it by changing the directory name 'AutoSuricata - Deb' to 'AutoSuricata-Deb'
	-discovered a bug with make install-full where suricata-update goes to execute suricata to get build information, and suricata fails to execute because it can't find libHTP. Its typically recommended to run ldconfig before attempting to run suricata, so the system /knows/ where newly installed libraries are, but make install-full doesn't do this before running suricata-update. This would cause suricata-update to fail, and the script to report failure due to returning a nonzero exit status for make install-full (as it should be). My (horrible) hack: run make install, then run ldconfig, then run make install-full. This fixes the problem. LD_PRELOAD has also been recommend as a solution, but I'm not sure it would resolve the problem. more testing to be done (TODO)

 -8-3-18
	-This script is now compatible with Ubuntu 18.04, in addition to Ubuntu 16.04
	-Fixed the pulledpork.conf this script generates. It now reflects the current version of pulledpork.pl (0.7.4)