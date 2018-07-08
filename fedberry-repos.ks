# Fedora Main
repo --name="fedora" --mirrorlist=http://mirrors.fedoraproject.org/metalink?repo=fedora-$releasever&arch=$basearch --excludepkgs="kernel-*,bcm283x-firmware,lightdm-gtk,bluez-*,linux-firmware,plymouth-*"

# Fedora Updates
repo --name="updates" --mirrorlist=http://mirrors.fedoraproject.org/metalink?repo=updates-released-f$releasever&arch=$basearch --excludepkgs="kernel-*,bcm283x-firmware,lightdm-gtk,bluez-*,linux-firmware,plymouth-*"

# FedBerry stable
repo --name="fedberry" --mirrorlist=https://fedberry.github.io/mirrorlist_stable_$releasever

# Edit this with your own repository
#repo --name="Local Repo" --baseurl=file:///path/to/folder/ --cost=600
