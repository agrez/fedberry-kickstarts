# Fedora Main
repo --name="fedora" --mirrorlist=https://mirrors.fedoraproject.org/mirrorlist?repo=fedora-$releasever&arch=$basearch --excludepkgs="kernel,kernel-*,bcm283x-firmware,lightdm-gtk,bluez,bluez-*,linux-firmware,plymouth,plymouth-*"

# Fedora Updates
repo --name="updates" --mirrorlist=https://mirrors.fedoraproject.org/mirrorlist?repo=updates-released-f$releasever&arch=$basearch --excludepkgs="kernel,kernel-*,bcm283x-firmware,lightdm-gtk,bluez,bluez-*,linux-firmware,plymouth,plymouth-*"

# FedBerry stable
repo --name="fedberry" --mirrorlist=https://fedberry.github.io/mirrorlist_stable_$releasever

# Edit this with your own repository
#repo --name="Local Repo" --baseurl=file:///path/to/folder/
