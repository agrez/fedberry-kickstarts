###
# Post-installation Scripts
###

### RPM & dnf related tweaking
%post
releasever=27
basearch=armhfp

# Work around for poor key import UI in PackageKit
rm -f /var/lib/rpm/__db*
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-fedberry-$releasever-primary

# Note that running rpm recreates the rpm db files which aren't needed or wanted
rm -f /var/lib/rpm/__db*

# remove random seed, the newly installed instance should make it's own
rm -f /var/lib/systemd/random-seed

### Remove various packages that refuse to not install themselves in the %packages sections :-/
dnf -y remove dracut-config-rescue
%end


### Having /tmp on tmpfs is enabled as this helps extend lifespan of sd cards
# However, size should be limited to 100M.
# This may cause issues for programs making heavy use of /tmp
%post
echo "Setting size limit of 100M for tmpfs for /tmp."
echo "tmpfs /tmp tmpfs    defaults,noatime,size=100m 0 0" >>/etc/fstab
%end


### Remove uboot images after kernel installation
%post
echo "Cleaning up uboot images"
rm -f /boot/uI*
%end


### Enable usb boot support for RPi3
%post --nochroot
echo "Use PARTUUID in /boot/cmdline.txt"
PARTUUID=$(/usr/sbin/blkid -s PARTUUID |awk '/\/dev\/loop0p2/ { print $2 }' |sed 's/"//g')
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


### Create swap file
%post
echo "Creating 512 MB swap file..."
dd if=/dev/zero of=/swapfile bs=1M count=512
/usr/sbin/mkswap /swapfile
# world readable swap files are a local vulnerability!
chmod 600 /swapfile &>/dev/null
echo "/swapfile swap swap defaults 0 0" >>/etc/fstab
%end


### Tweak systemd options
%post
echo "Setting systemd DefaultTimeoutStopSec to 20secs"
sed -i 's/#DefaultTimeoutStopSec=90s/DefaultTimeoutStopSec=20s/' /etc/systemd/system.conf
%end


### Remove machine-id on pre generated images
%post
rm -f /etc/machine-id
touch /etc/machine-id
%end


### Disable network service here. Doing it in services line fails due to RHBZ #1369794
%post
/sbin/chkconfig network off
%end


### Some space saving cleanups
%post
echo "Zeroing out empty space."
# This forces the filesystem to reclaim space from deleted files
dd bs=1M if=/dev/zero of=/var/tmp/zeros || :
rm -f /var/tmp/zeros

echo "Available space on rootfs: $(df -h |awk '/loop0p2/ { print $4 }')"
%end
