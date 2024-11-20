#
# Be sure to run `pod lib lint IPtProxyUI.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
	s.name             = 'IPtProxyUI'
	s.version          = '4.7.0'
	s.summary          = 'IPtProxyUI provides a UI to configure bridges for all Pluggable Transports available in the IPtProxy package.'

	s.description      = <<-DESC
	This package provides some scenes and configuration code which is shared between
	different apps using the `IPtProxy` package together with `Tor.framework`.

	The UI is complete for your users to configure all aspects of the Transports,
	including MOAT support to fetch new Obfs4 proxies.

	The configuration provided is good for using the PTs together with Tor.
	DESC

	s.homepage         = 'https://github.com/tladesignz/IPtProxyUI-ios'
	s.license          = { :type => 'MIT', :file => 'LICENSE' }
	s.author           = { 'Benjamin Erhart' => 'berhart@netzarchitekten.com' }
	s.source           = { :git => 'https://github.com/tladesignz/IPtProxyUI-ios.git', :tag => s.version.to_s }
	s.social_media_url = 'https://twitter.com/tladesignz'

	s.ios.deployment_target = '13.0'
	s.osx.deployment_target = '11'

	s.swift_version = '5.5'

	s.static_framework = true

	s.dependency 'IPtProxy', '~> 4.0.0'

	s.ios.dependency 'Eureka', '~> 5.3'

	s.subspec 'AppEx' do |a|
		a.preserve_paths = 'update-bridges.sh', 'update-bridges.swift', '.bartycrouch.toml'

		a.ios.source_files = 'IPtProxyUI/Classes/{Shared,iOS-AppEx}/**/*'
		a.osx.source_files = 'IPtProxyUI/Classes/{Shared,macOS}/**/*'

		a.ios.resource_bundles = {
			'IPtProxyUI' => ['IPtProxyUI/Assets/{Shared,iOS}/**/*']
		}
		a.osx.resource_bundles = {
			'IPtProxyUI' => ['IPtProxyUI/Assets/{Shared,macOS}/**/*']
		}

		a.script_phases = [
		{
			:name => 'Update Built-in Bridges',
			:script => '"$PODS_TARGET_SRCROOT/update-bridges.sh"',
			:execution_position => :before_compile,
			:output_files => ['iptproxy-appex-always-execute-this-but-supress-warning'],
		},
#		{
#			:name => 'BartyCrouch Automatic Localization',
#			:execution_position => :before_compile,
#			:script => <<-ENDSCRIPT
#if which bartycrouch > /dev/null; then
#	bartycrouch update -x -p "$PODS_TARGET_SRCROOT"
#	bartycrouch lint -x -p "$PODS_TARGET_SRCROOT"
#fi
#ENDSCRIPT
#		}
		]
	end

	s.subspec 'App' do |a|
		a.ios.dependency 'ProgressHUD', '~> 14.1'

		a.preserve_paths = 'update-bridges.sh', 'update-bridges.swift', '.bartycrouch.toml'

		a.ios.source_files = 'IPtProxyUI/Classes/{Shared,iOS-App,iOS-AppEx}/**/*'
		a.osx.source_files = 'IPtProxyUI/Classes/{Shared,macOS}/**/*'

		a.ios.resource_bundles = {
			'IPtProxyUI' => ['IPtProxyUI/Assets/{Shared,iOS}/**/*']
		}
		a.osx.resource_bundles = {
			'IPtProxyUI' => ['IPtProxyUI/Assets/{Shared,macOS}/**/*']
		}

		a.script_phases = [
		{
			:name => 'Update Built-in Bridges',
			:script => '"$PODS_TARGET_SRCROOT/update-bridges.sh"',
			:execution_position => :before_compile,
			:output_files => ['iptproxy-app-always-execute-this-but-supress-warning'],
		}
		]
	end

	s.default_subspec = 'App'
end
