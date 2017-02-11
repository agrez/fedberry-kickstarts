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

# Firewall configuration
firewall --enabled --service=mdns,ssh

# System authorization information
auth --useshadow --passalgo=sha512

# Run the Setup Agent on first boot
firstboot --reconfig

# SELinux configuration
selinux --enforcing

# System services
services --disabled="network,lvm2-monitor,dmraid-activation" --enabled="rootfs-grow,initial-setup,fake-hwclock"


# System bootloader configuration
# NOTE: /boot and swap MUST use --asprimary to ensure '/' is the last partition in order for rootfs-resize to work.

# Need to create logical volume groups first then partition
part /boot --fstype="vfat" --size 512 --label=BOOT --asprimary
part / --fstype="ext4" --size 3712 --grow --label=rootfs --asprimary
# Note: the --fsoptions & --fsprofile switches dont seem to work at all!
#  <SIGH> Need to edit fstab in %post :-(


###
# Packages
###

%packages
@core
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
@admin-tools
#arm-boot-config
chrony
dracut-config-generic
#extlinux-bootloader
gnome-keyring-pam
initial-setup
initial-setup-gui
system-config-printer
#uboot-images-armv7
wget
xscreensaver-extras
rfkill
# make sure all locales are available for inital-setup
glibc-all-langpacks
#vfat file system support tools
dosfstools
i2c-tools

### @base-x pulls in too many uneeded drivers.
xorg-x11-drv-evdev
xorg-x11-drv-modesetting
xorg-x11-xauth
xorg-x11-xinit
xorg-x11-server-Xorg
xorg-x11-utils
xorg-x11-drv-fbdev
mesa-dri-drivers
glx-utils

#Our kernel now has no dependency on linux-firmware as all essential firmware
#is included in release images. This helps minimise barebone image size.
linux-firmware

### FedBerry base specific packages
bcm283x-firmware
bcm43438-firmware
bcmstat
bluetooth-rpi3
fake-hwclock
fedberry-config
fedberry-local
fedberry-logos
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

### Remove misc packages
-fedora-logos
-fedora-release
-fedora-release-notes
-PackageKit*
-autofs
-acpid
-aspell-*
-desktop-backgrounds-basic
-gimp-help
-realmd
-xfce4-sensors-plugin


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
%end


### Remove various packages that refuse to not install themselves in the %packages sections :-/
%post
dnf -y remove dracut-config-rescue
%end


### Enable initial-setup gui mode
%post
echo "Enabling initial-setup gui mode on startup"
ln -s /usr/lib/systemd/system/initial-setup-graphical.service /etc/systemd/system/graphical.target.wants/initial-setup-graphical.service
%end


### Having /tmp on tmpfs is enabled as this helps extend lifespan of sd cards
# However, size should be limited to 100M.
# This may cause issues for programs making heavy use of /tmp
%post
echo "Setting size limit of 100M for tmpfs for /tmp."
echo "tmpfs /tmp tmpfs    defaults,noatime,size=100m 0 0" >>/etc/fstab
%end


### Need to ensure have our custom rpi2 kernel & firmware NOT the fedora kernel & firmware
%post
sed -i '/skip_if_unavailable=False/a exclude=kernel* perf python-perf bcm283x-firmware bluez' /etc/yum.repos.d/fedora*.repo
%end


### Tweak boot options
%post
echo "Modifying cmdline.txt boot options"
sed -i 's/nortc/nortc libahci.ignore_sss=1 raid=noautodetect/g' /boot/cmdline.txt
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


### Set gpu_mem=128 in /boot/config.txt
%post
sed -i s'/gpu_mem=32/gpu_mem=128/' /boot/config.txt
%end


### Set console framebuffer depth to 24bit
%post
sed -i s'/#framebuffer_depth=24/framebuffer_depth=24/' /boot/config.txt
%end


### Create swap file
%post
echo "Creating 512 MB swap file..."
dd if=/dev/zero of=/swapfile bs=1M count=512
/usr/sbin/mkswap /swapfile
#world readable swap files are a local vulnerability!
chmod 600 /swapfile &>/dev/null
echo "/swapfile swap swap defaults 0 0" >>/etc/fstab
%end


### Tweak xfwm4 options
%post
echo "Modifying default xfwm4 options"
# until vc4 is ready for prime time, disable compositing by default
sed -i 's/use_compositing=true/use_compositing=false/' /usr/share/xfwm4/defaults
%end


### Some space saving cleanups
%post
echo "cleaning yumdb"
rm -rf /var/lib/yum/yumdb/*

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
/usr/sbin/setfiles -F /etc/selinux/targeted/contexts/files/file_contexts /
/usr/sbin/setfiles -F /etc/selinux/targeted/contexts/files/file_contexts.homedirs /home/ /root/

umount -t tmpfs /sys/fs/selinux
mount -t tmpfs -o size=1 tmpfs /var/cache/yum
%end
