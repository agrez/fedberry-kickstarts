###
# Repositories
###

%include fedberry-repos.ks


###
# Kickstart Options
###

# System language
lang en_US.UTF-8 #--addsupport=de_DE.UTF-8,it_IT.UTF-8,es_ES.UTF-8,nl_NL.UTF-8,fr_FR.UTF-8,sv_SE.UTF-8

# Keyboard layouts
#keyboard --xlayouts=us,uk,de,fr,es

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
part / --fstype="ext4" --size 4736 --grow --label=rootfs --asprimary
# Note: the --fsoptions & --fsprofile switches dont seem to work at all!
#  <SIGH> Need to edit fstab in %post :-(


###
# Packages
###

### Fedberry base packages
%include fedberry-pkgs.ks

%packages
### FedBerry xfce remix specific packages
chromium
fedberry-local-chromium
fedberry-local-xfce-config
fedberry-local-gtk-config
fedberry-local-xorg-config
omxplayer-desktop
plymouth-theme-charge
%end

%packages
@admin-tools
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
# @xfce-office ## abiword is broken

dnfdragora
dracut-config-generic
glibc-all-langpacks
gnome-keyring-pam
gstreamer1-plugin-mpg123
gvfs-smb
initial-setup-gui
libreoffice-calc
libreoffice-writer
mpg123 ## mp3 support
system-config-printer
rfkill
wget
xfce4-mixer
xscreensaver-extras

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
-acpid
-aspell-*
-asunder
-autofs
-desktop-backgrounds-basic
-dnfdragora-gui ## just too buggy at present
-dnfdragora-updater ## just too buggy at present
-fedora-logos
-fedora-release
-fedora-release-notes
-firefox
-gimp-help
-kernel-modules-extra
-kernel-lpae-modules-extra
-jack-audio-connection-kit
-mpg123-plugins-jack
-PackageKit*
-rygel
-xfce4-sensors-plugin
-xfburn
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


#Some .desktop files are missing icons when using breeze icon theme
ln -s /usr/share/icons/breeze/categories/32/applications-utilities.svg /usr/share/icons/breeze/categories/32/applications-accessories.svg
ln -s /usr/share/icons/breeze/apps/48/internet-web-browser.svg /usr/share/icons/breeze/apps/48/web-browser.svg
ln -s /usr/share/icons/breeze/apps/48/mail-client.svg /usr/share/icons/breeze/apps/48/emblem-mail.svg
gtk-update-icon-cache /usr/share/icons/breeze
%end


%include fedberry-post.ks
