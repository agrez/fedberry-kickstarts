###
# RELEASE = 2
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


# An accelerated (limited to hardware accelerated window moving/scrolling) x.org video driver is available.
# Add to raspberrpi-local rpm package?
#%post
#cat > /etc/X11/xorg.conf.d/20-fbturbo.conf <<EOF
#Section "Device"
#    Identifier "Raspberry Pi FBDEV"
#    Driver "fbturbo"
#    Option "fbdev" "/dev/fb0"
#    Option "SwapbuffersWait" "true"
#EndSection
#EOF
#%end


# Resize root partition on first boot
%post
echo "Enabling resizing of root partition on first boot"
touch /.rootfs-repartition
touch /.resized
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

# raspberry Pi2 specific packages
xorg-x11-drv-fbturbo
python-rpi-gpio
raspberrypi-local
raspberrypi-vc-utils
raspberrypi-vc-libs
raspberrypi-repo

# we'll want to resize the rootfs on first boot
rootfs-resize

## Add Generic packages and remove fedora packages. 
generic-logos
generic-release
generic-release-notes
-fedora-logos
-fedora-release
-fedora-release-notes
#####

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
