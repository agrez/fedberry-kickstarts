###
# RELEASE=1-beta1
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
services --disabled="network,lvm2-monitor,dmraid-activation,ModemManager" --enabled="rootfs-grow,initial-setup,saveclock"


# Define how large you want your rootfs to be
# NOTE: /boot and swap MUST use --asprimary to ensure '/' is the last partition in order for rootfs-resize to work.
# Need to create logical volume groups first then partition
part /boot --fstype="vfat" --size 512 --label=BOOT --asprimary
part / --fstype="ext4" --size 4096 --grow --label=rootfs --asprimary
# Note: the --fsoptions & --fsprofile switches dont seem to work at all!
#  <SIGH> Need to edit fstab in %post :-(



###
# Packages
###

### Fedberry packages
%include fedberry-pkgs.ks
%packages

### FedBerry lxqt specific packages
compton
compton-conf
lxqt-common
lxqt-theme-fedberry
lxqt-panel
plymouth-theme-charge
qlipper
qpdfview
%end

%packages
@core
@fonts
@input-methods
@standard
@printing
@networkmanager-submodules
alsa-utils
blueman
chrony
claws-mail
#vfat file system support tools
dosfstools
firefox
gamin
# make sure all locales are available for inital-setup
glibc-all-langpacks
gstreamer1-plugin-mpg123
gvfs
gvfs-smb
i2c-tools
initial-setup
initial-setup-gui
libreoffice-writer
libreoffice-calc
#kwin & sddm pull in too many plasma desktop deps
#sddm is too slow on RPi2 (see https://github.com/sddm/sddm/issues/323). Workarounds don't seem to help.
#sddm also doesn't (yet?) support XDMCP.
lightdm
lightdm-gtk
lxmenu-data
mpg123
pulseaudio
rng-tools
sayonara
setroubleshoot
system-config-printer
system-config-language
system-config-keyboard
transmission-qt
#trojita (not built for f26/27 armv7hl?) sylpheed or claws-mail?
wget
xarchiver
xscreensaver-extras


### @lxqt pulls in too many plasma desktop deps
breeze-cursor-theme
breeze-gtk
breeze-icon-theme
dnfdragora
featherpad
firewall-config
lxqt-admin
lxqt-about
#lxqt-common # from Fedberry packages
lxqt-config
lxqt-config-randr
lxqt-globalkeys
lxqt-notificationd
lxqt-openssh-askpass
# lxqt-panel # from Fedberry packages
lxqt-policykit
lxqt-powermanagement
lxqt-qtplugin
lxqt-runner
lxqt-session
lxqt-sudo
lxqt-wallet
lximage-qt
lxtask
lxappearance
nm-connection-editor
notification-daemon
obconf-qt
openbox
pcmanfm-qt
perl-File-MimeInfo
qt5-qtstyleplugins
qterminal
upower
xdg-user-dirs


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


### Packages to Remove
-fedberry-headless
-fedora-release
-fedora-release-notes
-fprintd-pam
-ibus-typing-booster
-pcmciautils
-kernel-headers

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
sed -i -e s'/gpu_mem=32/gpu_mem=128/' /boot/config.txt
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


### Edit some default options
%post
echo "Modifying openbox defaults"
# update openbox theme & number of desktops
sed -i -e 's/Clearlooks/Onyx/' /etc/xdg/openbox/rc.xml

echo "Modifying xscreensaver defaults"
sed -i -e 's|mode:\(.*\)random|mode:\1blank|' -e 's|lock:\(.*\)True|lock:\1False|' /etc/xscreensaver/XScreenSaver.ad.header
/usr/sbin/update-xscreensaver-hacks

echo "Creating x-lxqt-mimeapps.list defaults"
cat >/etc/xdg/x-lxqt-mimeapps.list<<EOF
[Default Applications]
text/plain=featherpad.desktop
[Added Associations]
text/plain=featherpad.desktop;
EOF

# Enable compton by default for a smoother desktop experience.
# This also stops LXQt start problems (when loggin in) when using VC4
sed -i -e 's/Hidden/#Hidden/' /etc/xdg/autostart/lxqt-compton.desktop

echo "Setting gtk2 theme defaults"
mkdir /etc/gtk-2.0
cat >/etc/gtk-2.0/gtkrc<<EOF
gtk-theme-name="Breeze"
gtk-icon-theme-name="breeze"
gtk-font-name="Sans 10"
gtk-cursor-theme-name="Breeze_Snow"
gtk-button-images=0
gtk-menu-images=0
EOF

echo "Setting gtk3 theme defaults"
mkdir /etc/gtk-3.0
cat >/etc/gtk-3.0/settings.ini<<EOF
[Settings]
gtk-theme-name=Breeze
gtk-icon-theme-name=breeze
gtk-font-name=Sans 10
gtk-cursor-theme-name=Breeze_Snow
gtk-button-images=0
gtk-menu-images=0
EOF

#lxqt menu is missing an icon when use breeze icon theme
ln -s /usr/share/icons/breeze/categories/32/applications-utilities.svg /usr/share/icons/breeze/categories/32/applications-accessories.svg
gtk-update-icon-cache /usr/share/icons/breeze
%end


%include fedberry-post.ks
