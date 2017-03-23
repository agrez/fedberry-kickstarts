###
# RELEASE=1-beta1
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
services --disabled="network,lvm2-monitor,dmraid-activation" --enabled="rootfs-grow,initial-setup,headless-check,fake-hwclock"


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
### Fedora packages
@core
@hardware-support
#arm-boot-config
chrony
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
#vfat file system support tools
dosfstools
i2c-tools

#Our kernel now has no dependency on linux-firmware as all essential firmware
#is included in release images. This helps minimise barebone image size.
linux-firmware

# FedBerry specific packages
bcm283x-firmware
bcm43438-firmware
bcmstat
bluetooth-rpi3
fake-hwclock
fedberry-config
fedberry-headless
fedberry-local
fedberry-release
fedberry-release-notes
fedberry-repo
fedberry-selinux-policy
kernel
python2-RPi.GPIO
python3-RPi.GPIO
raspberrypi-vc-libs
raspberrypi-vc-utils
wiringpi

### Remove packages
-@dial-up
-@standard
-initial-setup-gui
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
sed -i '/skip_if_unavailable=False/a exclude=kernel* perf python-perf bcm283x-firmware bluez' /etc/yum.repos.d/fedora*.repo
%end


### Remove uboot images after kernel installation
%post
echo "Cleaning up uboot images"
rm -f /boot/uI*
%end


### Tweak boot options
%post
echo "Modifying cmdline.txt boot options"
sed -i 's/ rhgb plymouth.ignore-serial-consoles logo.nologo//' /boot/cmdline.txt
%end


### Set colour depth to 16bit
%post
sed -i s'/#framebuffer_depth=16/framebuffer_depth=16/' /boot/config.txt
%end


### Enable usb boot support for RPi3
%post --nochroot
echo "Use PARTUUID in /boot/cmdline.txt"
PARTUUID=$(/usr/sbin/blkid -s PARTUUID |awk '/loop0p2/ { print $2 }' |sed 's/"//g')
sed -i "s|/dev/mmcblk0p2|$PARTUUID|" $INSTALL_ROOT/boot/cmdline.txt
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
echo "Zeroing out empty space."
# This forces the filesystem to reclaim space from deleted files
dd bs=1M if=/dev/zero of=/var/tmp/zeros || :
rm -f /var/tmp/zeros
%end
