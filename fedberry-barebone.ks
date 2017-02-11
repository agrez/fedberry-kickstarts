###
# RELEASE=1-alpha1
###


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
services --disabled="network" --enabled="fake-hwclock"


#
# Define how large you want your rootfs to be
#
# NOTE: /boot and swap MUST use --asprimary to ensure '/' is the last partition in order for rootfs-resize to work.

# Need to create logical volume groups first then partition
part /boot --fstype="vfat" --size 512 --label="BOOT" --asprimary
part / --fstype="ext4" --size 2048 --grow --label="rootfs" --asprimary
# Note: the --fsoptions & --fsprofile switches dont seem to work at all!
#  <SIGH> Will have to edit fstab in %post :-(



###
# Packages
###

%packages --instLangs=en_US.utf8 --excludedocs
@core
NetworkManager-wifi
glibc-langpack-en
#vfat file system support tools
dosfstools
i2c-tools

# DNF has 'issues' with time travel!
chrony

# FedBerry specific packages
bcm283x-firmware
bcm43438-firmware
bcmstat
bluetooth-rpi3
fake-hwclock
fedberry-config
fedberry-local
fedberry-release
fedberry-release-notes
fedberry-repo
kernel
python2-RPi.GPIO
python3-RPi.GPIO
raspberrypi-vc-libs
raspberrypi-vc-utils
wiringpi

# Packages to Remove
-gsettings-desktop-schemas
-selinux-policy
-selinux-policy-targeted
-plymouth*
%end



###
# Post-installation Scripts
###

### RPM & dnf related tweaking
%post
releasever=25
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


#### Need to ensure have our custom rpi2/3 kernels & firmware NOT the fedora kernel & firmware
%post
sed -i '/skip_if_unavailable=False/a exclude=kernel* perf python-perf bcm283x-firmware bluez' /etc/yum.repos.d/fedora*.repo
%end


### Tweak boot options
%post
echo "Modifying cmdline.txt boot options"
sed -i 's/nortc/nortc libahci.ignore_sss=1 raid=noautodetect selinux=0 audit=0/g' /boot/cmdline.txt
%end


### Edit fstab options manually
%post
echo "Modifying fstab options"
sed -i 's/ext4.*defaults/ext4    defaults,data=writeback/' /etc/fstab
%end


### Disable audio interface by default
%post
sed -i s'/dtparam=audio=on/#dtparam=audio=on/' /boot/config.txt
%end


### Keep systemd's journal size under control
%post
echo "Setting systemd max journal size to 20M"
sed -i 's/#SystemMaxUse=/SystemMaxUse=20/' /etc/systemd/journald.conf
%end


### Need some more agressive space saving cleanups for 'barebone' builds
%post
echo "Removing firewalld service"
dnf -C -y autoremove firewalld

echo "Removing linux-firmware"
# Note: At some point firmware will get pulled back in when the kernel is updated.
rpm -e --nodeps linux-firmware
%end

# Ugggh.... this is a hacky workaround! Since linux-firmware now contains brcmfmac43430-sdio.bin,
# we can't include it in bcm43438-firmware (it conflicts). Just install manually for now :-/
%post --nochroot
echo "Installing brcmfmac43430 firmware"
curl -o $INSTALL_ROOT/usr/lib/firmware/brcm/brcmfmac43430-sdio.bin http://git.kernel.org/cgit/linux/kernel/git/firmware/linux-firmware.git/plain/brcm/brcmfmac43430-sdio.bin
chmod 644 $INSTALL_ROOT/usr/lib/firmware/brcm/brcmfmac43430-sdio.bin
%end

%post
echo "cleaning yumdb"
rm -rf /var/lib/yum/yumdb/*

echo "Cleaning up pre-compiled python files"
find /usr/ | grep -E "(__pycache__|\.pyc|\.pyo$)" | xargs rm -rf

echo "Zeroing out empty space."
# This forces the filesystem to reclaim space from deleted files
dd bs=1M if=/dev/zero of=/var/tmp/zeros || :
rm -f /var/tmp/zeros
%end
