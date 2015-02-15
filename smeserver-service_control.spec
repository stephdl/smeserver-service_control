%define name smeserver-service_control
%define version 2.2
%define release 5
Summary: SME Server service control Panel
Name: %{name}
Version: %{version}
Release: %{release}%{?dist}
Distribution: SME Server
License: GNU GPL version 2
Group: SMEserver/addon
Source: %{name}-%{version}.tar.gz
BuildArchitectures: noarch
BuildRoot: /var/tmp/%{name}-%{version}-buildroot
BuildRequires: e-smith-devtools
Requires: e-smith-release >= 9.0
AutoReqProv: no


%changelog
* Sun Feb 15 2015 stephane de labrusse <stephdl@de-labrusse.fr> - 2.2-5
- Services with localhost access are now manageable
- Cosmetic changes in the Panel
- Optimisation of service2adjust in createlinks

* Wed Feb 13 2015 stephane de labrusse <stephdl@de-labrusse.fr> - 2.2-4
- New expand-template of service-expand with a link to bootstrap-console-save
- sigusr1 to httpd when service-expand is called 

* Wed May 21 2014 stephane de labrusse <stephdl@de-labrusse.fr> - 2.0-3
- adaptation to git use, creation of service2adjust by createlinks

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
