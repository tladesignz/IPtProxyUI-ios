#
# Be sure to run `pod lib lint IPtProxyUI.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
	s.name             = 'IPtProxyUI'
	s.version          = '1.6.0'
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
	# s.social_media_url = 'https://twitter.com/tladesignz'

	s.ios.deployment_target = '11.0'

	s.swift_version = '5.5'

	s.preserve_paths = 'update-bridges.swift', '.bartycrouch.toml'

	s.source_files = 'IPtProxyUI/Classes/**/*'

	s.resource_bundles = {
		'IPtProxyUI' => ['IPtProxyUI/Assets/**/*']
	}

	s.static_framework = true

	s.script_phases = [
		{
			:name => 'Update Built-in Bridges',
			:script => '"$PODS_TARGET_SRCROOT/update-bridges.swift"',
			:execution_position => :before_compile
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

	s.dependency 'IPtProxy', '~> 1.5'
	s.dependency 'Eureka', '~> 5.3'
	s.dependency 'ImageRow', '~> 4.0'
	s.dependency 'MBProgressHUD', '~> 1.2'
	s.dependency 'ReachabilitySwift', '~> 5.0'

end
