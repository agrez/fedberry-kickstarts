%define bname   fedberry
%define name    %{bname}-kickstarts
%define version 25
%define release 1

Name:       %{name}
Version:    %{version}
Release:    %{release}%{?dist}
License:    GPLv2+
Summary:    Kickstart files for creating FedBerry Remixes
Group:      Applications/System
URL:        https://github.com/fedberry/fedberry-kickstarts
Source0:    https://raw.githubusercontent.com/%{bname}/%{name}/master/%{bname}-repos.ks
Source1:    https://raw.githubusercontent.com/%{bname}/%{name}/master/%{bname}-mini.ks
Source2:    https://raw.githubusercontent.com/%{bname}/%{name}/master/%{bname}-minimal.ks
Source3:    https://raw.githubusercontent.com/%{bname}/%{name}/master/%{bname}-xfce.ks
Source4:    https://raw.githubusercontent.com/%{bname}/%{name}/master/%{bname}-lxqt.ks
BuildArch:  noarch

%description
Various kickstarts used to create FedBerry Remixes

%prep
%setup -c -T
cp -a %{sources} .

%build

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT%{_datadir}/spin-kickstarts
install -m 644 *.ks $RPM_BUILD_ROOT%{_datadir}/spin-kickstarts/


%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%{_datadir}/spin-kickstarts/*.ks


%changelog
* Thu Jun 01 2017 Vaughan <vaughan at agrez dot net> 25-1
- Update for FedBerry 25

* Fri Feb 05 2016 Vaughan <vaughan at agrez dot net> 23-1
- Initial release
