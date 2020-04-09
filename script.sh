yum install -y gcc make rpm-build libtool hwloc-devel libX11-devel libXt-devel libedit-devel libical-devel ncurses-devel perl            postgresql-devel python-devel tcl-devel  tk-devel swig expat-devel openssl-devel libXext libXft wget postgresql-server
yum install -y rpmdevtools
rpmdev-setuptree
tar -xpvf pbspro-18.1.4.tar.gz
cd pbspro-18.1.4
./autogen.sh
./configure
make dist
mv pbspro-18.1.4.tar.gz ~/rpmbuild/SOURCES
cp pbspro.spec ~/rpmbuild/SPECS
cd ~/rpmbuild/SPECS
rpmbuild -ba pbspro.spec
