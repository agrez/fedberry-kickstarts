###
# RELEASE = 1-beta1
###


###
# Repositories
###

%include fedberry-repos.ks


# System language
lang en_US.UTF-8

# Firewall configuration
firewall --enabled --service=mdns,ssh

# System authorization information
auth --useshadow --passalgo=sha512

# Run the Setup Agent on first boot
firstboot --reconfig

# SELinux configuration
selinux --enforcing

# Set root password
rootpw fedberry

# System services
services --disabled="network,lvm2-monitor,dmraid-activation" --enabled="rootfs-grow,initial-setup,headless-check"


#
# Define how large you want your rootfs to be
#
# NOTE: /boot and swap MUST use --asprimary to ensure '/' is the last partition in order for rootfs-resize to work.

## Need to create logical volume groups first then partition
part /boot --fstype="vfat" --size 512 --label=BOOT --asprimary
part / --fstype="ext4" --size 1824 --grow --fsoptions="noatime" --label=rootfs --asprimary



###
# Packages
###

%packages
# Fedora packages
@core
@hardware-support
#arm-boot-config
chrony
dosfstools
dracut-config-generic
#extlinux-bootloader
initial-setup
nano
NetworkManager-wifi
glibc-langpack-en
bash-completion
GeoIP
hardlink
timedatex
trousers
policycoreutils
#uboot-images-armv7

# FedBerry specific packages
kernel-4.4.19-401.5ba1281.bcm2709.fc24.armv7hl
bcm283x-firmware
bcm43438-firmware
fedberry-release
fedberry-release-notes
fedberry-repo
fedberry-local
fedberry-config
fedberry-selinux-policy
fedberry-headless
raspberrypi-vc-utils
raspberrypi-vc-libs
python2-RPi.GPIO
python3-RPi.GPIO
bluetooth-rpi3

# Remove packages
-@dial-up
-@standard
-initial-setup-gui
-uboot-tools
%end



###
# Post-installation Scripts
###

### RPM & dnf related tweaking
%post
releasever=24
basearch=armhfp

# Work around for poor key import UI in PackageKit
rm -f /var/lib/rpm/__db*
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-fedberry-$releasever-primary

# Note that running rpm recreates the rpm db files which aren't needed or wanted
rm -f /var/lib/rpm/__db*

# remove random seed, the newly installed instance should make it's own
rm -f /var/lib/systemd/random-seed

# Because memory is scarce resource in most arm systems we are differing from the Fedora
# default of having /tmp on tmpfs.
echo "Disabling tmpfs for /tmp."
systemctl mask tmp.mount

dnf -y remove dracut-config-generic
%end


### Setup systemd to boot to the right runlevel
%post
echo "Setting default runlevel to multiuser text mode"
rm -f /etc/systemd/system/default.target
ln -s /lib/systemd/system/multi-user.target /etc/systemd/system/default.target
%end


### Need to ensure have our custom rpi2/3 kernel & firmware
%post
sed -i '/skip_if_unavailable=False/a exclude=kernel* bcm283x-firmware bluez' /etc/yum.repos.d/fedora*.repo
%end


### Remove uboot images after kernel installation
%post
echo "Cleaning up uboot images"
rm -f /boot/uI*
%end


### Enable fsck for rootfs & boot partitions
%post
echo "Enabling fsck for rootfs & boot partitions"
#rootfs
sed -i 's| \/ \(.*\)0 0| \/ \10 1|' /etc/fstab
#boot
sed -i 's| \/boot \(.*\)0 0| \/boot \10 2|' /etc/fstab
%end


### Grow root filesystem on first boot
%post
echo "Enabling expanding of root partition on first boot"
touch /.rootfs-repartition
%end


### Create swap file
%post
echo "Creating 512 MB swap file..."
dd if=/dev/zero of=/swapfile bs=1M count=512
/usr/sbin/mkswap /swapfile
# world readable swap files are a local vulnerability!
chmod 600 /swapfile &>/dev/null
echo "/swapfile swap swap defaults 0 0" >>/etc/fstab
%end


### Expire the current root password (forces new password on first login)
%post
passwd -e root
%end


### Some space saving cleanups
%post
echo "Zeroing out empty space."
# This forces the filesystem to reclaim space from deleted files
dd bs=1M if=/dev/zero of=/var/tmp/zeros || :
rm -f /var/tmp/zeros
%end


### Misc work around(s) for selinux troubles! :-/
%post
# fixes chronyd avc denial (net-pf-10)
echo "Toggle selinux domain_kernel_load_modules boolean"
/usr/sbin/setsebool -P domain_kernel_load_modules 1

# Relabel filesystem as it fails to do this after %post
# Needs to be the last %post action to catch any files we've created/modified.
# Also replaces /var/cache/yum with a fake mount after relabelling.
mount -t tmpfs -o size=1 tmpfs /sys/fs/selinux
umount /var/cache/yum

echo "Relabeling filesystem"
/usr/sbin/setfiles -F -e /proc -e /dev /etc/selinux/targeted/contexts/files/file_contexts /
/usr/sbin/setfiles -F /etc/selinux/targeted/contexts/files/file_contexts.homedirs /home/ /root/

umount -t tmpfs /sys/fs/selinux
mount -t tmpfs -o size=1 tmpfs /var/cache/yum
%end
