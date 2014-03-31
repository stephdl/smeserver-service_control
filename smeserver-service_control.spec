%define name smeserver-service_control
%define version 2.0
%define release 2
Summary: SME Server service control Panel
Name: %{name}
Version: %{version}
Release: %{release}%{?dist}
Distribution: SME Server
License: GNU GPL version 2
Group: SMEserver/addon
Source: %{name}-%{version}.tar.gz
#Patch0: smeserver-service_control-2.0-utf8.patch
BuildArchitectures: noarch
BuildRoot: /var/tmp/%{name}-%{version}-buildroot
BuildRequires: e-smith-devtools
Requires: e-smith-release >= 8.0
AutoReqProv: no


%changelog
* Wed Jan 22 2014 stephane de labrusse <stephdl@de-labrusse.fr>
- first release for SME Server 8.0 thanks to Michel Van hees for his work
- Adaptation to utf8

* Mon Feb 11 2008 Michel Van hees <michel@vanhees.cc>
- Adding Access service swap

* Mon Jan 21 2008 Michel Van hees <michel@vanhees.cc>
- Code cleaning

* Mon Jan 21 2008 Michel Van hees <michel@vanhees.cc>
- Adding confirmation screen

* Tue Jan 15 2008 Michel Van hees <michel@vanhees.cc>
- Fix bug in server-manager menu

* Mon Jan 14 2008 Michel Van hees <michel@vanhees.cc>
- Fix bug in TCP Port panel

* Mon Jan 14 2008 Michel Van hees <michel@vanhees.cc>
- First release

%description
sme server administration panel to control service status and tcp port

%prep
%setup
#%patch0 -p1
#%patch1 -p1

%build
perl createlinks

%install
rm -rf $RPM_BUILD_ROOT
(cd root   ; find . -depth -print | cpio -dump $RPM_BUILD_ROOT)
rm -f %{name}-%{version}-filelist
/sbin/e-smith/genfilelist $RPM_BUILD_ROOT > %{name}-%{version}-filelist
echo "%doc COPYING"          >> %{name}-%{version}-filelist

%clean 
rm -rf $RPM_BUILD_ROOT

%pre
%preun

%post
#/etc/e-smith/events/actions/navigation-conf > /dev/null 2>&1
#echo Go to your server-manager to use new function

%postun
#/etc/e-smith/events/actions/navigation-conf > /dev/null 2>&1

%files -f %{name}-%{version}-filelist
%defattr(-,root,root)
