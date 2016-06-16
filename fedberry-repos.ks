# Fedora Main
repo --name="fedora" --mirrorlist=http://mirrors.fedoraproject.org/metalink?repo=fedora-$releasever&arch=$basearch --cost=1000

# Fedora Updates
repo --name="updates" --mirrorlist=http://mirrors.fedoraproject.org/metalink?repo=updates-released-f$releasever&arch=$basearch --cost=1000

# FedBerry stable
repo --name="fedberry" --baseurl=http://download.fedberry.org/releases/$releasever/packages/armhfp/stable/ --cost=800
#repo --name="fedberry" --baseurl=https://vaughan.fedorapeople.org/releases/$releasever/packages/armhfp/stable/ --cost=800

# FedBerry Testing
#repo --name="fedberry-testing" --baseurl=http://download.fedberry.org/releases/$releasever/packages/armhfp/testing/ --cost=600
#repo --name="fedberry-testing" --baseurl=https://vaughan.fedorapeople.org/releases/$releasever/packages/armhfp/testing/ --cost=600

# Edit this with your own repository
#repo --name="Local Repo" --baseurl=file:///path/to/folder/ --cost=600
