This is a special release of autosuricata meant to be used as a part of Project:AVATAR. This installer script provides the following functionality:

-Downloads required pre-reqs to run and compile suricata
-Downloads suricata-currrent and compiles it with the make install-full option. Suricata is installed to /usr/local/bin/suricata, while suricata's supporting files are installed to /usr/local/etc/suricata
-Installs suricata-update for rule management
-Configures suricata for inline mode operation via af-packet bridging
-Installes the "suricatad" init script for service persistence
-Very stripped-down: This installer does NOT install barnyard2, or include any options to install an interface of any sort. This installs pulledpork, and Suricata with some persistence, and that's it.
-Inline mode operation: This installer requires a minimum of 3 network interfaces to work properly. Two interfaces will be placed into inline mode via the AFPACKET DAQ. ARP will be disabled on these interfaces, meaning that your system will NOT respond to any traffic sent to these interfaces.

This installer, and its supporting files are meant to be consumed with PROJECT:AVATAR, my massive virtual lab book. Particularly, the chapter entitled "IDS/IPS" installation. All the instructions you should need should be included in the book.

Instructions:
fill out full_autosuricata.conf, then run "autosuricata-deb-AVATAR.sh" as root. Wait for the system to reboot, and you should be all set.

Thanks,

da_667

4-26-19

-Decided that it was time to stop installing pulledpork. Suricata has the suricata-update rule manager, and not only that, its included with the install. And is officially supported.
-Discovered that at some point between now, and the last version of this script, that the suricata project has decided that suricata rules live elsewhere when you run make install-full than t/usr/local/etc/suricata/rules. Fixed this by running suricata -update -D /usr/local/etc/suricata
-Additionally, while doing this update, figured out that some rules that are enabled by default rely on some of the protocol-event.rules files that are shipped in the suricata source tarball. If these rules are NOT available, whenever you attempt to test your suricata config, you will get several warnings about rules that check for certain flowbits to be set, but those rules not being available. These rules do NOT get downloaded with suricata-update for reasons entirely beyond me, so to fix THAT issue:
-the suricata source tarball is now downloaded to /usr/src
-the protocol-event.rules (e.g. tls-events, http-events, etc.) are copied over to /usr/local/etc/suricata/rules
-suricata-update is ran with the --no-merge flag so you can see what rule categories are enabled and have more granular control of your rules.

11-12-18

Ubuntu 18.04 users:
-apparently, when I tested, I didn't test things well enough. Ran into a problem where users who installed ubuntu 18.04.1 server from ISO (as opposed to doing do-release-upgrade to 18.04.1 from ubuntu 16.04.x) have a different /etc/apt/sources.list and are unable to install all of the requisite packages. Fixed this by:
--making a backup of /etc/apt/sources.list in case users have custom repos they enabled
--blowing away the existing sources.list and replacing with with the default repos from a fresh ubuntu 18.04 install with the "universe" repo installed in addition to the "main" repo
--if the backup file exists, we assume its due to a failed script run and do NOT over write it (e.g. if /etc/apt/sources.list.bak exists, we do NOT overwrite it)
--advise the user if they have custom repos configured for their apt sources.list file, to restore them from the backup file we made -- /etc/apt/sources.list.bak
-noticed that in spite of having the libraries for a bunch of enhanced features (e.g. hiredis, geoip, and lua support), that suricata was compiling without support for any of these features.
- change the "./configure" portion of the installer to enable support for extra features. Suricata is now compiled with support for:
--rust
--geoip
--hiredis
--lua
--liblz4
--liblzma
-decided that since rust is a programming language that is subject to constant updating, that using rust-init to install rustc and cargo is probably for the best, since Linux distro packages tend to lag behind. Both 18.04 and 16.04 users install rustc and cargo via rust-init now.

11-09-18
-Suricata 4.1.0 came out, and with it, rust has become a dominant force in the suricata development community.
-re-worked the dependencies that get installed, per the readthedocs documentation. Recommended dependencies, including rust dependencies are now installed.
-suricata-update, what appears to be some sort of a rule manager for suricata, is installed. without it, make install-full fails to complete. While suricata-update is apparently the new way to manage Suricata rules, I'm opting to install pulledpork (and its dependencies) to ensure that users who are use to its syntax can keep using it.
-python-pip installed in order to install suricata-update and pyyaml dependency
-discovered a bug where compiling suricata with rust features fails because rust/cargo target path variable can't deal with directory paths that have spaces. This seems like an upstream bug, but I fixed it by changing the directory name 'AutoSuricata - Deb' to 'AutoSuricata-Deb'
-discovered a bug with make install-full where suricata-update goes to execute suricata to get build information, and suricata fails to execute because it can't find libHTP. Its typically recommended to run ldconfig before attempting to run suricata, so the system /knows/ where newly installed libraries are, but make install-full doesn't do this before running suricata-update. This would cause suricata-update to fail, and the script to report failure due to returning a nonzero exit status for make install-full (as it should be). My (horrible) hack: run make install, then run ldconfig, then run make install-full. This fixes the problem. LD_PRELOAD has also been recommend as a solution, but I'm not sure it would resolve the problem. more testing to be done (TODO)

8-3-18
-This script is now compatible with Ubuntu 18.04, in addition to Ubuntu 16.04
-Fixed the pulledpork.conf this script generates. It now reflects the current version of pulledpork.pl (0.7.4)