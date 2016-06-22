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

# System services
services --disabled="network,lvm2-monitor,dmraid-activation" --enabled="ssh,NetworkManager,avahi-daemon,rsyslog,chronyd,rootfs-grow,initial-setup"


#
# Define how large you want your rootfs to be
#
# NOTE: /boot and swap MUST use --asprimary to ensure '/' is 
#       the last partition in order for rootfs-resize to work.
#
# System bootloader configuration

## Need to create logical volume groups first then partition
part /boot --fstype="vfat" --size 512 --label=BOOT --asprimary
part / --fstype="ext4" --size 3200 --grow --fsoptions="noatime" --label=rootfs --asprimary

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

# remove random seed, the newly installed instance should make it's own
rm -f /var/lib/systemd/random-seed

# Because memory is scarce resource in most arm systems we are differing from the Fedora
# default of having /tmp on tmpfs.
echo "Disabling tmpfs for /tmp."
systemctl mask tmp.mount

dnf -y remove dracut-config-generic
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

# Enable fsck for rootfs & boot partitions
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

%post
# Set gpu_mem=128 in config.txt!
sed -i s'/gpu_mem=32/gpu_mem=128/' /boot/config.txt
%end

%post
# Set console framebuffer depth to 24bit
sed -i s'/#framebuffer_depth=24/framebuffer_depth=24/' /boot/config.txt
%end


# Create swap file
%post
echo "Creating 512 MB swap file..."
dd if=/dev/zero of=/swapfile bs=1M count=512
/usr/sbin/mkswap /swapfile
#world readable swap files are a local vulnerability!
chmod 600 /swapfile &>/dev/null
echo "/swapfile swap swap defaults 0 0" >>/etc/fstab
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
kernel-4.4.13-400.789e0e5.bcm2709.fc24.armv7hl
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
bcm43438-firmware
raspberrypi-vc-utils
raspberrypi-vc-libs
python2-RPi.GPIO
python3-RPi.GPIO
bluetooth-rpi3

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
