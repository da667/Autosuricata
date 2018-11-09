This is a special release of autosuricata meant to be used as a part of Project:AVATAR. This installer script provides the following functionality:

-Downloads required pre-reqs to run and compile suricata
-Downloads suricata-currrent and compiles it with the make install-full option (Which downloads and installs the ET Open ruleset). Suricata is installed to /usr/local/bin/suricata, while suricata's supporting files are installed to /usr/local/etc/suricata
-Downloads pulledpork.pl to /usr/src/pulledpork, and creates a stripped-down pulledpork.conf in /usr/src/pulledpork/etc
-Configures suricata for inline mode operation via af-packet bridging
-Installes the "suricatad" init script for service persistence
-Very stripped-down: This installer does NOT install barnyard2, or include any options to install an interface of any sort. This installs pulledpork, and Suricata with some persistence, and that's it.
-Inline mode operation: This installer requires a minimum of 3 network interfaces to work properly. Two interfaces will be placed into inline mode via the AFPACKET DAQ. ARP will be disabled on these interfaces, meaning that your system will NOT respond to any traffic sent to these interfaces.
-Pulledpork.pl is installed but is NOT configured to run. Because the Emerging Threats ruleset doesn't really include a default ruleset, I leave it as an exercise to the user if they want to learn how to customize and manage their rules.

This installer, and its supporting files are meant to be consumed with PROJECT:AVATAR, my massive virtual lab book. Particularly, the chapter entitled "IDS/IPS" installation. All the instructions you should need should be included in the book.

Instructions:
fill out full_autosuricata.conf, then run "autosuricata-deb-AVATAR.sh" as root. Wait for the system to reboot, and you should be all set.

Thanks,

da_667

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