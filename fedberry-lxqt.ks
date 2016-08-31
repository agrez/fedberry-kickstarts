###
# RELEASE = 1-beta1
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
services --disabled="network,lvm2-monitor,dmraid-activation" --enabled="rootfs-grow,initial-setup,headless-check"


# System bootloader configuration
# NOTE: /boot and swap MUST use --asprimary to ensure '/' is the last partition in order for rootfs-resize to work.

# Need to create logical volume groups first then partition
part /boot --fstype="vfat" --size 512 --label=BOOT --asprimary
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
@networkmanager-submodules
alsa-plugins-pulseaudio
chrony
initial-setup
initial-setup-gui
lightdm
lightdm-gtk
gamin
gvfs
gvfs-smb
wget
yumex-dnf
generic-logos
xarchiver
lxmenu-data
#vfat file system support tools
dosfstools

### @lxqt pulls in too many plasma desktop deps
breeze-cursor-theme
breeze-gtk
breeze-icon-theme
firewall-config
lxqt-admin
lxqt-about
lxqt-common
lxqt-config
lxqt-config-randr
lxqt-globalkeys
lxqt-notificationd
lxqt-openssh-askpass
lxqt-panel
lxqt-policykit
lxqt-powermanagement
lxqt-qtplugin
lxqt-runner
lxqt-session
lxqt-wallet
network-manager-applet
nm-connection-editor
notification-daemon
obconf
openbox
pcmanfm-qt
perl-File-MimeInfo
qterminal-qt5
qupzilla
upower
xdg-user-dirs
lximage-qt
#kwin & sddm pull in too many plasma desktop deps
#sddm is too slow on RPi2 (see https://github.com/sddm/sddm/issues/323). Workarounds don't seem to help.
#sddm also doesn't (yet?) support XDMCP.


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

### FedBerry specific packages
kernel-4.4.19-401.5ba1281.bcm2709.fc24.armv7hl
bcm283x-firmware
bcm43438-firmware
fedberry-release
fedberry-release-notes
fedberry-repo
fedberry-local
fedberry-config
fedberry-selinux-policy
raspberrypi-vc-utils
raspberrypi-vc-libs
python2-RPi.GPIO
python3-RPi.GPIO
bluetooth-rpi3
featherpad
compton

### Packages to Remove
-fedora-release
-fedora-release-notes
-fedora-logos
-fprintd-pam
-ibus-typing-booster
-pcmciautils
-qterminal

### Unwanted fonts
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
sed -i '/skip_if_unavailable=False/a exclude=kernel* bcm283x-firmware bluez' /etc/yum.repos.d/fedora*.repo
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


### Create swap file
%post
echo "Creating 512 MB swap file..."
dd if=/dev/zero of=/swapfile bs=1M count=512
/usr/sbin/mkswap /swapfile
#world readable swap files are a local vulnerability!
chmod 600 /swapfile &>/dev/null
echo "/swapfile swap swap defaults 0 0" >>/etc/fstab
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
/usr/sbin/setfiles -F -e /proc -e /dev /etc/selinux/targeted/contexts/files/file_contexts /
/usr/sbin/setfiles -F /etc/selinux/targeted/contexts/files/file_contexts.homedirs /home/ /root/

umount -t tmpfs /sys/fs/selinux
mount -t tmpfs -o size=1 tmpfs /var/cache/yum
%end
