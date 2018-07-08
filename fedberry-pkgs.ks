###
# Fedberry Base Packages
###

%packages

# Core packages
bcm283x-firmware
bcm434xx-firmware
bcmstat
bluetooth-rpi3
chrony ## DNF has 'issues' with time travel!
dosfstools ## vfat file system support tools
fedberry-config
fedberry-local
fedberry-release
fedberry-release-notes
fedberry-repo
fedberry-selinux-policy
i2c-tools
initial-setup
kernel
nano
NetworkManager-wifi
omxplayer
python2-RPi.GPIO
python3-RPi.GPIO
raspberrypi-vc-libs
raspberrypi-vc-utils
saveclock
wiringpi

#Our kernel now has no dependency on linux-firmware as all essential firmware
#is included in release images. This helps minimise barebone image size.
linux-firmware

### Packages to Remove
-alsa-plugins-pulseaudio ## alsa over pulseaudio is still buggy
-iwl*
-ipw*
-iproute-tc
-kernel-headers
-libcangjie
-trousers-lib
-usb_modeswitch

### Thin out fonts
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
