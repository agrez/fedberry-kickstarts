###
# Repositories
###

%include fedberry-repos.ks


###
# Kickstart Options
###

# System language
lang en_US.UTF-8
keyboard us
timezone US/Eastern

# Firewall configuration
firewall --disabled

# System authorization information
auth --useshadow --passalgo=sha512
rootpw fedberry

# SELinux configuration
selinux --disabled

# System services
services --disabled="network,sssd" --enabled="saveclock"


# Define how large you want your rootfs to be
# NOTE: /boot and swap MUST use --asprimary to ensure '/' is the last partition in order for rootfs-resize to work.
# Need to create logical volume groups first then partition
part /boot --fstype="vfat" --size 512 --label="BOOT" --asprimary
part / --fstype="ext4" --size 2048 --grow --label="rootfs" --asprimary
# Note: the --fsoptions & --fsprofile switches dont seem to work at all!
#  <SIGH> Will have to edit fstab in %post :-(



###
# Packages
###

### Fedberry packages
%include fedberry-pkgs.ks

### Fedora packages
%packages --instLangs=en_US.utf8 --excludedocs
@core
# DNF has 'issues' with time travel!
chrony
#vfat file system support tools
dosfstools
glibc-langpack-en
i2c-tools
NetworkManager-wifi

### Remove packages
-fedberry-headless
-fedberry-selinux-policy
-linux-firmware
-omxplayer
-selinux-policy
-selinux-policy-targeted
-trousers
%end



###
# Post-installation Scripts
###

### RPM & dnf related tweaking
%post
releasever=27
basearch=armhfp

# Work around for poor key import UI in PackageKit
rm -f /var/lib/rpm/__db*
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-fedberry-$releasever-primary

# Note that running rpm recreates the rpm db files which aren't needed or wanted
rm -f /var/lib/rpm/__db*

# remove random seed, the newly installed instance should make it's own
rm -f /var/lib/systemd/random-seed

# Don't need this!
dnf -y remove dracut-config-rescue

# Use only en_US language for rpms
echo %_install_langs en_US.utf8 >> /etc/rpm/macros

# Disable delta rpms as many of them don't install correctly as
# we save space by excluding docs & only install the en_US.utf8 language)
echo "deltarpm=0" >>/etc/dnf/dnf.conf
%end

### Expire the current root password (forces new password on first login)
%post
passwd -e root
%end


### Having /tmp on tmpfs is enabled as this helps extend lifespan of sd cards
# However, size should be limited to 100M.
# This may cause issues for programs making heavy use of /tmp
%post
echo "Setting size limit of 100M for tmpfs for /tmp."
echo "tmpfs /tmp tmpfs    defaults,noatime,size=100m 0 0" >>/etc/fstab
%end


#### Setup systemd to boot to the right runlevel
%post
echo "Setting default runlevel to multiuser text mode"
rm -f /etc/systemd/system/default.target
ln -s /lib/systemd/system/multi-user.target /etc/systemd/system/default.target
%end


### Tweak systemd options
%post
echo "Setting systemd DefaultTimeoutStopSec to 30secs"
sed -i 's/#DefaultTimeoutStopSec=90s/DefaultTimeoutStopSec=30s/' /etc/systemd/system.conf

#systemd-hwdb-update service won't disable for some reason :-/
#rebuilding /etc/udev/hwdb.bin @ every boot takes time!
echo "Masking systemd systemd-hwdb-update.service"
/usr/bin/systemctl mask systemd-hwdb-update.service
%end


#### Need to ensure have our custom rpi2/3 kernels & firmware NOT the fedora kernel & firmware
%post
sed -i '/skip_if_unavailable=False/a exclude=bcm283x-firmware bluez kernel* lightdm-gtk perf plymouth* python-perf' /etc/yum.repos.d/fedora*.repo
%end


### Tweak boot options
%post
echo "Modifying cmdline.txt boot options"
sed -i 's/nortc/nortc selinux=0 audit=0/' /boot/cmdline.txt
%end


### Enable usb boot support for RPi3
%post --nochroot
echo "Use PARTUUID in /boot/cmdline.txt"
PARTUUID=$(/usr/sbin/blkid -s PARTUUID |awk '/\/dev\/loop0p2/ { print $2 }' |sed 's/"//g')
sed -i "s|/dev/mmcblk0p2|$PARTUUID|" $INSTALL_ROOT/boot/cmdline.txt
%end


### Disable audio interface by default
%post
sed -i s'/dtparam=audio=on/#dtparam=audio=on/' /boot/config.txt
%end


### Set colour depth to 16bit
%post
sed -i s'/#framebuffer_depth=16/framebuffer_depth=16/' /boot/config.txt
%end


### Keep systemd's journal size under control
%post
echo "Setting systemd max journal size to 20M"
sed -i 's/#SystemMaxUse=/SystemMaxUse=20/' /etc/systemd/journald.conf
%end


### Remove machine-id on pre generated images
%post
rm -f /etc/machine-id
touch /etc/machine-id
%end


### Disable network service here. Doing it in services line fails due to RHBZ #1369794
%post
/sbin/chkconfig network off
%end


### Some space saving cleanups
%post
echo "Removing firewalld service"
dnf -C -y autoremove firewalld

echo "cleaning yumdb"
rm -rf /var/lib/yum/yumdb/*

echo "Cleaning up pre-compiled python files"
find /usr/ | grep -E "(__pycache__|\.pyc|\.pyo$)" | xargs rm -rf

echo "Zeroing out empty space."
# This forces the filesystem to reclaim space from deleted files
dd bs=1M if=/dev/zero of=/var/tmp/zeros || :
rm -f /var/tmp/zeros

echo "Available space on rootfs: $(df -h |awk '/loop0p2/ { print $4 }')"
%end
