###
# Fedberry Base Packages
###

%packages

# Core FedBerry packages
bcm283x-firmware
bcm43438-firmware
bcmstat
bluetooth-rpi3
saveclock
fedberry-config
fedberry-headless
fedberry-local
fedberry-release
fedberry-release-notes
fedberry-repo
fedberry-selinux-policy
kernel
omxplayer
python2-RPi.GPIO
python3-RPi.GPIO
raspberrypi-vc-libs
raspberrypi-vc-utils
wiringpi

#Our kernel now has no dependency on linux-firmware as all essential firmware
#is included in release images. This helps minimise barebone image size.
linux-firmware

### Packages to Remove
-iwl*
-ipw*
-trousers
-usb_modeswitch
-iproute-tc
%end
