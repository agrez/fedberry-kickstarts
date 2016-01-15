###
# Repositories
###

%include f23-fedberry-repos.ks


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
services --disabled="network,lvm2-monitor,dmraid-activation" --enabled="ssh,NetworkManager,avahi-daemon,rsyslog,chronyd"


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
part /boot --fstype="vfat" --size 300 --label=BOOT --asprimary
part swap --fstype="swap" --size 1000 --asprimary
part / --fstype="ext4" --size 1200 --grow --fsoptions="noatime" --label=rootfs --asprimary


%post
# work around for poor key import UI in PackageKit
rm -f /var/lib/rpm/__db*
releasever=$(rpm -q --qf '%{version}\n' fedora-release)
basearch=armhfp
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
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

echo -n "Enabling initial-setup text mode on startup"
ln -s /usr/lib/systemd/system/initial-setup-text.service /etc/systemd/system/multi-user.target.wants/initial-setup-text.service
echo .
%end


# Give the remix a better name than 'generic'
# This is hacky! Need to make my own fedberry-release rpm
%post
sed -i -e 's/Generic release/RPi2 Fedora Remix/g' /etc/fedora-release /etc/issue /etc/issue.net
sed -i -e 's/(Generic)/(Twenty Three)/g' /etc/fedora-release /etc/issue /etc/issue.net
sed -i 's/NAME=Generic/NAME="RPi2 Fedora Remix"/g' /etc/os-release
sed -i 's/ID=generic/ID=FedBerry/g' /etc/os-release
sed -i 's/(Generic)/(Twenty Three)/g' /etc/os-release
sed -i '/ID=FedBerry/a ID_LIKE="rhel fedora"' /etc/os-release
sed -i 's/Generic 23/RPi2 Fedora Remix 23/g' /etc/os-release
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


# Resize root partition on first boot
%post
echo "Enabling resizing of root partition on first boot"
touch /.rootfs-repartition
touch /.resized
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
kernel
kernel-tools
nano
perf
#uboot-images-armv7
-@dial-up
-@standard
-initial-setup-gui
-uboot-tools

# raspberry Pi2 specific packages
python-rpi-gpio
raspberrypi-local
raspberrypi-vc-utils
raspberrypi-vc-libs
raspberrypi-repo


# we'll want to resize the rootfs on first boot
rootfs-resize

# Add Generic packages and remove fedora packages. 
-fedora-release
-fedora-release-notes
generic-release
generic-release-notes
%end
