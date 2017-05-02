# Fedora Main
repo --name="fedora" --mirrorlist=http://mirrors.fedoraproject.org/metalink?repo=fedora-$releasever&arch=$basearch

# Fedora Updates
repo --name="updates" --mirrorlist=http://mirrors.fedoraproject.org/metalink?repo=updates-released-f$releasever&arch=$basearch

# FedBerry stable
repo --name="fedberry" --mirrorlist=https://fedberry.github.io/mirrorlist_stable

# FedBerry Testing
#repo --name="fedberry-testing" ---mirrorlist=https://fedberry.github.io/mirrorlist_testing

# Edit this with your own repository
#repo --name="Local Repo" --baseurl=file:///path/to/folder/ --cost=600
