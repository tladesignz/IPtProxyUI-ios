#
# Be sure to run `pod lib lint IPtProxyUI.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
	s.name             = 'IPtProxyUI'
	s.version          = '1.0.0'
	s.summary          = 'IPtProxyUI provides a UI to configure bridges for all Pluggable Transports available in the IPtProxy package.'

	# This description is used to generate tags and improve search results.
	#   * Think: What does it do? Why did you write it? What is the focus?
	#   * Try to keep it short, snappy and to the point.
	#   * Write the description between the DESC delimiters below.
	#   * Finally, don't worry about the indent, CocoaPods strips it!

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

	s.ios.deployment_target = '9.3'

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
		{
			:name => 'BartyCrouch Automatic Localization',
			:execution_position => :before_compile,
			:script => <<-SCRIPT
			if which bartycrouch > /dev/null; then
				bartycrouch update -x -p "$PODS_TARGET_SRCROOT"
				bartycrouch lint -x -p "$PODS_TARGET_SRCROOT"
			fi
			SCRIPT
		}
	]

	s.dependency 'IPtProxy', '~> 1.2'
	s.dependency 'Eureka', '~> 5.3'
	s.dependency 'ImageRow', '~> 4.0'
	s.dependency 'MBProgressHUD', '~> 1.2'

end
