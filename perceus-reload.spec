Summary: Reload the Perceus DB with flat-file content
Name: perceus-reload
Version: 1.0
Release: 2
Group: Applications/System
Source0: %{name}.pl
BuildRoot: %{_tmppath}/%{name}-%{version}-root
License: BSD, modified
Requires: perl, perceus >= 1.5.0
BuildArch: noarch
Packager: Daryl W. Grunau <dwg@lanl.gov>
Prefix: %{_bindir}

%description
Perceus-reload reads in node configuration information from /etc/perceus/nodes.conf
and (re)creates Perceus DB information with it.

# no prep required
#%setup

# no build required
#%build

%install
umask 022
%{__rm} -rf $RPM_BUILD_ROOT

%{__mkdir_p} $RPM_BUILD_ROOT%{_bindir}
%{__install} -m 0750 %SOURCE0 $RPM_BUILD_ROOT%{_bindir}/%{name}

%clean
%{__rm} -rf $RPM_BUILD_ROOT

%files
%defattr(0644,root,root,0755)
%attr(0750,root,root) %{_bindir}/%{name}

%changelog
* Thu Jul 28 2011 Daryl W. Grunau <dwg@lanl.gov> 1.0-2
- Require perceus >= 1.5.0

* Thu Jul 28 2011 Daryl W. Grunau <dwg@lanl.gov> 1.0-1
- First cut.
