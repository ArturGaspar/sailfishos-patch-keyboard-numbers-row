Name:       patch-keyboard-numbers-row
Summary:    Patch for numbers row
Version:    0
Release:    0
License:    MIT
URL:        https://github.com/ArturGaspar/sailfishos-%{name}
Source0:    %{name}-%{version}.tar.bz2
BuildArch:  noarch
Requires:   patchmanager

%description
Patch for adding a numbers row to the keyboard

%prep
%setup -q -n %{name}-%{version}

%build
touch src/unified_diff.patch

%install
rm -rf %{buildroot}
install -D -m 0755 -t %{buildroot}%{_libexecdir} src/%{name}.sh
install -D -m 0644 -t %{buildroot}%{_datadir}/patchmanager/patches/%{name} src/patch.json
install -D -m 0644 -t %{buildroot}%{_sharedstatedir}/%{name} src/unified_diff.patch
ln -s %{_sharedstatedir}/%{name}/unified_diff.patch %{buildroot}%{_datadir}/patchmanager/patches/%{name}/unified_diff.patch

%files
%defattr(-,root,root,-)
%{_libexecdir}/%{name}.sh
%{_datadir}/patchmanager/patches/%{name}
%{_sharedstatedir}/%{name}

%posttrans
%{_libexecdir}/%{name}.sh > %{_sharedstatedir}/%{name}/unified_diff.patch

%triggerin -- jolla-keyboard
%{_libexecdir}/%{name}.sh > %{_sharedstatedir}/%{name}/unified_diff.patch

%triggerpostun -- jolla-keyboard
%{_libexecdir}/%{name}.sh > %{_sharedstatedir}/%{name}/unified_diff.patch

%triggerin -- jolla-keyboard-layout-chinese
%{_libexecdir}/%{name}.sh > %{_sharedstatedir}/%{name}/unified_diff.patch

%triggerpostun -- jolla-keyboard-layout-chinese
%{_libexecdir}/%{name}.sh > %{_sharedstatedir}/%{name}/unified_diff.patch

%triggerin -- jolla-keyboard-layout-indian
%{_libexecdir}/%{name}.sh > %{_sharedstatedir}/%{name}/unified_diff.patch

%triggerpostun -- jolla-keyboard-layout-indian
%{_libexecdir}/%{name}.sh > %{_sharedstatedir}/%{name}/unified_diff.patch

%triggerin -- jolla-keyboard-layout-kazakh
%{_libexecdir}/%{name}.sh > %{_sharedstatedir}/%{name}/unified_diff.patch

%triggerpostun -- jolla-keyboard-layout-kazakh
%{_libexecdir}/%{name}.sh > %{_sharedstatedir}/%{name}/unified_diff.patch

%triggerin -- jolla-keyboard-layout-russian
%{_libexecdir}/%{name}.sh > %{_sharedstatedir}/%{name}/unified_diff.patch

%triggerpostun -- jolla-keyboard-layout-russian
%{_libexecdir}/%{name}.sh > %{_sharedstatedir}/%{name}/unified_diff.patch

%triggerin -- jolla-keyboard-layout-tatar
%{_libexecdir}/%{name}.sh > %{_sharedstatedir}/%{name}/unified_diff.patch

%triggerpostun -- jolla-keyboard-layout-tatar
%{_libexecdir}/%{name}.sh > %{_sharedstatedir}/%{name}/unified_diff.patch

%triggerin -- jolla-keyboard-layout-western
%{_libexecdir}/%{name}.sh > %{_sharedstatedir}/%{name}/unified_diff.patch

%triggerpostun -- jolla-keyboard-layout-western
%{_libexecdir}/%{name}.sh > %{_sharedstatedir}/%{name}/unified_diff.patch
