###
# RELEASE=1-rc1
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
part / --fstype="ext4" --size 4384 --grow --label=rootfs --asprimary
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
#@xfce-office #abiword is broken
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
glibc-all-langpacks
dosfstools
i2c-tools
plymouth-theme-charge
libreoffice-writer
libreoffice-calc
#mp3 support
mpg123
gstreamer1-plugin-mpg123


# workaround for consequence of RHBZ #1324623: without this, with
# yum-based creation tools, compose fails due to conflict between
# libcrypt and libcrypt-nss. dnf does not seem to have the same
# issue, so this may be dropped when appliance-creator is ported
# to dnf.
libcrypt-nss
-libcrypt

### @base-x pulls in too many uneeded drivers.
xorg-x11-drv-evdev
xorg-x11-drv-fbturbo
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
chromium
fake-hwclock
fedberry-config
fedberry-local
fedberry-logos
fedberry-release
fedberry-release-notes
fedberry-repo
fedberry-selinux-policy
kernel-4.9.24-1.rpi.fc25.armv7hl
kernel-core-4.9.24-1.rpi.fc25.armv7hl
kernel-modules-4.9.24-1.rpi.fc25.armv7hl
kernel-modules-extra-4.9.24-1.rpi.fc25.armv7hl
omxplayer
python2-RPi.GPIO
python3-RPi.GPIO
raspberrypi-vc-libs
raspberrypi-vc-utils
wiringpi


### Remove misc packages
-kernel-4.10.12-200.fc25.armv7hl
-kernel-core-4.10.12-200.fc25.armv7hl
-kernel-modules-4.10.12-200.fc25.armv7hl
-kernel-modules-extra-4.10.12-200.fc25.armv7hl
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
-firefox
# pulse audio is too buggy on RPi's
-alsa-plugins-pulseaudio
%end


###
# Post-installation Scripts
###

### RPM & dnf related tweaking
%post
echo -e "/nPerforming RPM & dnf related tweaking"
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
dnf -y remove kernel-headers
echo -e "\nPackages installed in this image:"
rpm -qa
%end


### Explicitly set graphical.target as default as this is how initial-setup detects which version to run
%post
echo -e "\nSetting graphical.target as default"
ln -sf /lib/systemd/system/graphical.target /etc/systemd/system/default.target
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
sed -i '/skip_if_unavailable=False/a exclude=bcm283x-firmware bluez kernel* lightdm-gtk perf plymouth* python-perf' /etc/yum.repos.d/fedora*.repo
%end


### Tweak boot options
%post
echo "Enabling plymouth"
sed -i 's/quiet/quiet rhgb plymouth.ignore-serial-consoles logo.nologo/' /boot/cmdline.txt
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


### Default to using fbturbo xorg driver (vc4 is still too buggy)
%post
cat > /etc/X11/xorg.conf.d/20-fbturbo.conf <<EOF
Section "Device"
    Identifier "Raspberry Pi FBDEV"
    Driver "fbturbo"
    Option "fbdev" "/dev/fb0"
    Option "SwapbuffersWait" "true"
EndSection
EOF
%end


### Use ALSA directly without being hooked by pulseaudio as pulseaudio is problematic on RPi's
%post
echo "Default to using ALSA directly without being hooked by pulseaudio"
sed -i s'/#load-module module-alsa-sink/load-module module-alsa-sink device=dmix/' /etc/pulse/default.pa
sed -i s'/#load-module module-alsa-source.*$/load-module module-alsa-source device=dsnoop/' /etc/pulse/default.pa
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


### Edit some default options
%post
echo "Modifying xscreensaver defaults"
sed -i -e 's|mode:\(.*\)random|mode:\1blank|' -e 's|lock:\(.*\)True|lock:\1False|' /etc/xscreensaver/XScreenSaver.ad.header
/usr/sbin/update-xscreensaver-hacks
%end



### Disable network service here. Doing it in services line fails due to RHBZ #1369794
%post
/sbin/chkconfig network off
%end


### Remove machine-id on pre generated images
%post
rm -f /etc/machine-id
touch /etc/machine-id
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
