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
auth --useshadow --enablemd5
# Run the Setup Agent on first boot
firstboot --reconfig
# SELinux configuration
selinux --enforcing
# Installation logging level
logging --level=info
# System services
services --disabled="network,lvm2-monitor,dmraid-activation" --enabled="ssh,NetworkManager,avahi-daemon,rsyslog,chronyd,rootfs-grow,initial-setup"


#
# Define how large you want your rootfs to be
#
# NOTE: /boot and swap MUST use --asprimary to ensure '/' is 
#       the last partition in order for rootfs-resize to work.
#
# System bootloader configuration

bootloader --location=boot
#zerombr
#clearpart --all
## Need to create logical volume groups first then partition
part /boot --fstype="vfat" --size 512 --label=BOOT --asprimary
part swap --fstype="swap" --size 1000 --asprimary
part / --fstype="ext4" --size 1200 --grow --fsoptions="noatime" --label=rootfs --asprimary


%post
# work around for poor key import UI in PackageKit
rm -f /var/lib/rpm/__db*
releasever=24
basearch=armhfp
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-fedberry-$releasever-primary
echo "Packages within this ARM disk image"
rpm -qa
# Note that running rpm recreates the rpm db files which aren't needed or wanted
rm -f /var/lib/rpm/__db*

# Because memory is scarce resource in most arm systems we are differing from the Fedora
# default of having /tmp on tmpfs.
echo "Disabling tmpfs for /tmp."
systemctl mask tmp.mount

# Arm boot config
#/usr/sbin/a-b-c

yum -y remove dracut-config-generic
%end


%post
# setup systemd to boot to the right runlevel
echo -n "Setting default runlevel to multiuser text mode"
rm -f /etc/systemd/system/default.target
ln -s /lib/systemd/system/multi-user.target /etc/systemd/system/default.target
echo .
%end


# Need to ensure have our custom rpi2 kernel & firmware NOT the fedora kernel & firmware
%post
sed -i '/skip_if_unavailable=False/a exclude=kernel* bcm283x-firmware' /etc/yum.repos.d/fedora-updates.repo
%end


# Remove uboot images after kernel installation
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


# Grow root filesystem on first boot
%post
echo "Enabling expanding of root partition on first boot"
touch /.rootfs-repartition
%end


%packages
@core
@hardware-support
#arm-boot-config
chrony
dosfstools
dracut-config-generic
#extlinux-bootloader
initial-setup
kernel-4.4.13-400.789e0e5.bcm2709.fc24.armv7hl
kernel-tools-4.4.13-400.789e0e5.bcm2709.fc24.armv7hl
nano
perf
NetworkManager-wifi
#uboot-images-armv7
-@dial-up
-@standard
-initial-setup-gui
-uboot-tools

# FedBerry specific packages
fedberry-release
fedberry-release-notes
fedberry-repo
fedberry-local
fedberry-config
bcm43438-firmware
raspberrypi-vc-utils
raspberrypi-vc-libs
python2-RPi.GPIO
python3-RPi.GPIO
bluetooth-rpi3

# Remove fedora packages. 
-fedora-release
-fedora-release-notes
%end
