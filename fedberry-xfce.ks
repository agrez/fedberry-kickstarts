###
# RELEASE = 2-test1
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

# System services
services --disabled="network,lvm2-monitor,dmraid-activation" --enabled="ssh,NetworkManager,avahi-daemon,rsyslog,chronyd,rootfs-grow"


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
part / --fstype="ext4" --size 3200 --grow --fsoptions="noatime" --label=rootfs --asprimary

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

#/usr/sbin/a-b-c

yum -y remove dracut-config-generic

%end


# We need to ensure have the custom rpi2 kernel NOT the generic fedora kernel
%post
sed -i '/skip_if_unavailable=False/a exclude=kernel* bcm283x-firmware' /etc/yum.repos.d/fedora-updates.repo
%end


# Remove uboot images after kernel installation
%post
rm -f /boot/uI*
%end


%post
echo "Enabling initial-setup gui mode on startup"
ln -s /usr/lib/systemd/system/initial-setup-graphical.service /etc/systemd/system/graphical.target.wants/initial-setup-graphical.service
echo .
%end


# Grow root filesystem on first boot
%post
echo "Enabling expanding of root partition on first boot"
touch /.rootfs-repartition
%end

%post
# Set gpu_mem=128 in config.txt!
sed -i s'/gpu_mem=32/gpu_mem=128/' /boot/config.txt
%end

%packages
@base-x
@core
@dial-up
@fonts
@hardware-support
@input-methods
@multimedia
@networkmanager-submodules
@printing
@standard
@xfce-apps
@xfce-desktop
@xfce-extra-plugins
@xfce-media
@xfce-office
#arm-boot-config
chrony
dracut-config-generic
#extlinux-bootloader
gnome-keyring-pam
initial-setup
initial-setup-gui
kernel
system-config-printer
#uboot-images-armv7
wget
xscreensaver-extras

# FedBerry specific packages
fedberry-release
fedberry-release-notes
fedberry-repo
fedberry-local
fedberry-config
raspberrypi-vc-utils
raspberrypi-vc-libs
python-rpi-gpio

# Add Generic logos & remove fedora packages.
generic-logos
-fedora-logos
-fedora-release
-fedora-release-notes

-PackageKit*
-acpid
-aspell-*
-autofs
-desktop-backgrounds-basic
-gimp-help
-realmd
-uboot-tools
-xfce4-sensors-plugin

%end
