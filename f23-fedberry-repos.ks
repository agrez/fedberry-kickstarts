# Fedora Main
repo --name="fedora" --mirrorlist=http://mirrors.fedoraproject.org/metalink?repo=fedora-$releasever&arch=$basearch --cost=1000

# Fedora Updates
repo --name="updates" --mirrorlist=http://mirrors.fedoraproject.org/metalink?repo=updates-released-f$releasever&arch=$basearch --cost=1000

# Raspberry Pi 2 RPMS for Fedora
repo --name="rpi2-repo" --baseurl=https://vaughan.fedorapeople.org/fed23/RPMS/ --cost=500

# Edit this with your own repository
#repo --name="Local Repo" --baseurl=file:///home/raspberry/repo/fed23/RPMS/ --cost=500

