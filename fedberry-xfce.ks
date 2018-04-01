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
services --disabled="network,lvm2-monitor,dmraid-activation,ModemManager" --enabled="rootfs-grow,initial-setup,saveclock"

# Define how large you want your rootfs to be
# NOTE: /boot and swap MUST use --asprimary to ensure '/' is the last partition in order for rootfs-resize to work.
# Need to create logical volume groups first then partition
part /boot --fstype="vfat" --size 512 --label=BOOT --asprimary
part / --fstype="ext4" --size 4480 --grow --label=rootfs --asprimary
# Note: the --fsoptions & --fsprofile switches dont seem to work at all!
#  <SIGH> Need to edit fstab in %post :-(


###
# Packages
###

### Fedberry packages
%include fedberry-pkgs.ks

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
xfce4-mixer
#@xfce-office #abiword is broken
@admin-tools
#arm-boot-config
chrony
dracut-config-generic
firefox
gnome-keyring-pam
initial-setup
initial-setup-gui
system-config-printer
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
gvfs-smb

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


### Remove misc packages
-fedberry-headless
-fedora-logos
-fedora-release
-fedora-release-notes
-PackageKit*
-autofs
-acpid
-aspell-*
-desktop-backgrounds-basic
-gimp-help
-xfce4-sensors-plugin
-xfburn
-asunder
-kernel-headers
%end


###
# Post-installation Scripts
###

### Explicitly set graphical.target as default as this is how initial-setup detects which version to run
%post
echo -e "\nSetting graphical.target as default"
ln -sf /lib/systemd/system/graphical.target /etc/systemd/system/default.target
%end


### Tweak boot options
%post
echo "Enabling plymouth"
sed -i 's/quiet/quiet rhgb plymouth.ignore-serial-consoles logo.nologo/' /boot/cmdline.txt
%end


### Set gpu_mem=128 in /boot/config.txt
%post
sed -i s'/gpu_mem=32/gpu_mem=128/' /boot/config.txt
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


%include fedberry-post.ks
