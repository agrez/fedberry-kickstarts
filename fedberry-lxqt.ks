###
# RELEASE = 2-test1
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
firewall --enabled --service=mdns,ssh,samba-client

# System authorization information
auth --useshadow --passalgo=sha512

# Run the Setup Agent on first boot
firstboot --reconfig

# SELinux configuration
selinux --enforcing

# System services
services --disabled="network,lvm2-monitor,dmraid-activation" --enabled="ssh,NetworkManager,avahi-daemon,rsyslog,chronyd,rootfs-grow"


# System bootloader configuration# Define how large you want your rootfs to be
# NOTE: /boot and swap MUST use --asprimary to ensure '/' is the last partition in order for rootfs-resize to work.
bootloader --location=boot
# Need to create logical volume groups first then partition
part /boot --fstype="vfat" --size 256 --label=BOOT --asprimary
part swap --fstype="swap" --size 1024 --asprimary
part / --fstype="ext4" --size 3200 --grow --label=rootfs --asprimary
# Note: the --fsoptions & --fsprofile switches dont seem to work at all!
#  <SIGH> Need to edit fstab in %post :-(



###
# Packages
###

%packages
@core
@fonts
@input-methods
@standard
@lxqt
@networkmanager-submodules
kernel-4.4.13-400.789e0e5.bcm2709.fc24.armv7hl
alsa-plugins-pulseaudio
lxmenu-data
chrony
initial-setup
initial-setup-gui
#sddm is too slow on RPi2 (see https://github.com/sddm/sddm/issues/323). Workarounds don't seem to help.
#sddm also doesn't (yet?) support XDMCP.
lightdm
lightdm-gtk
gamin
gvfs
gvfs-smb
wget
#would like to find a light & fast qt5 replacement for leafpad
leafpad
yumex
# yumex-dnf is buggy under arm for some reason (no problems under x86 arch!)
qterminal-qt5

# @base-x pulls in too many uneeded drivers.
xorg-x11-drv-evdev
xorg-x11-drv-modesetting
xorg-x11-xauth
xorg-x11-xinit
xorg-x11-server-Xorg
xorg-x11-utils
xorg-x11-drv-fbdev
mesa-dri-drivers
glx-utils

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

# Add Generic logos & remove fedora packages.
generic-logos
-fedora-logos
-fedora-release
-fedora-release-notes

### Packages to Remove
-fprintd-pam
-ibus-typing-booster
-sddm
-pcmciautils
-qterminal

# Unwanted fonts
-lohit-*
-sil-*
-adobe-source-han-sans-cn-fonts
-adobe-source-han-sans-tw-fonts
-google-noto-sans-tai-viet-fonts
-google-noto-sans-mandaic-fonts
-google-noto-sans-lisu-fonts
-google-noto-sans-tagalog-fonts
-google-noto-sans-tai-tham-fonts
-google-noto-sans-meetei-mayek-fonts
-lklug-fonts
-vlgothic-fonts
-khmeros-base-fonts
-paktype-naskh-basic-fonts
-tabish-eeyek-fonts
-smc-meera-fonts
-thai-scalable-waree-fonts
-jomolhari-fonts
-naver-nanum-gothic-fonts
%end


###
# Post-installation Scripts
###

### RPM & dnf related tweaking
%post
# Work around for poor key import UI in PackageKit
rm -f /var/lib/rpm/__db*
releasever=24
basearch=armhfp
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-rpi2

# Note that running rpm recreates the rpm db files which aren't needed or wanted
rm -f /var/lib/rpm/__db*
%end


### Remove various packages that refuse to not install themselves in the %packages sections :-/
%post
dnf -y remove dracut-config-rescue uboot-tools
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
sed -i '/skip_if_unavailable=False/a exclude=kernel* bcm283x-firmware' /etc/yum.repos.d/fedora-updates.repo
%end


### Tweak boot options
%post
echo "Modifying cmdline.txt boot options"
sed -i 's/nortc/nortc libahci.ignore_sss=1 raid=noautodetect/g' /boot/cmdline.txt
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
sed -i -e s'/gpu_mem=32/gpu_mem=128/' /boot/config.txt
%end


### Set console framebuffer depth to 24bit
%post
sed -i s'/#framebuffer_depth=24/framebuffer_depth=24/' /boot/config.txt
%end


### Edit some lxqt default options
%post
echo "Modifying LXQt defaults"
sed -i 's/single_click_activate=false/single_click_activate=true/' /etc/xdg/lxqt/lxqt.conf
%end


### Edit some lightdm default options
%post
echo "Modifying lightdm defaults"
sed -i 's|background=/usr/share/backgrounds/default.png|background=/usr/share/lxqt/themes/frost/numix.png|' /etc/lightdm/lightdm-gtk-greeter.conf
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
