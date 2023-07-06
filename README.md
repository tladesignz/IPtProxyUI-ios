# IPtProxyUI

[![Version](https://img.shields.io/cocoapods/v/IPtProxyUI.svg?style=flat)](https://cocoapods.org/pods/IPtProxyUI)
[![License](https://img.shields.io/cocoapods/l/IPtProxyUI.svg?style=flat)](https://cocoapods.org/pods/IPtProxyUI)
[![Platform](https://img.shields.io/cocoapods/p/IPtProxyUI.svg?style=flat)](https://cocoapods.org/pods/IPtProxyUI)

IPtProxyUI provides a UI to configure bridges for all Pluggable Transports available in the IPtProxy package.

This package provides some scenes and configuration code which is shared between
different apps using the `IPtProxy` package together with `Tor.framework`.

The UI is complete for your users to configure all aspects of the Transports,
including MOAT/rdsys support to fetch new Obfs4 proxies.

The configuration provided is good for using the PTs together with Tor.

Additionally there's a helper class `IpSupport` which can aid in better supporting
IPv6-only networks which are common with some mobile network carriers.


## Installation

IPtProxyUI is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'IPtProxyUI'
```

## Getting Started

```swift
use IPtProxyUI

// ATTENTION: Since IPtProxy 2.0.0 this needs to be set explicitly before starting a transport!
Settings.stateLocation = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("pt_state")

Transport.obfs4.start(log: true)

print((try? String(contentsOf: Transport.obfs4.logFile!)) ?? "throwed")

Transport.obfs4.stop()
```


## Localization

Localization is done with [BartyCrouch](https://github.com/Flinesoft/BartyCrouch),
licensed under [MIT](https://github.com/Flinesoft/BartyCrouch/blob/main/LICENSE).

Just add new `NSLocalizedStrings` calls to the code. After a build, they will 
automatically show up in [`Localizable.strings`](IPtProxyUI/Assets/en.lproj/Localizable.strings).

Don't use storyboard and xib file localization. That just messes up everything.
Localize these by explicit calls in the code.


## Dependencies

- [IPtProxy](https://github.com/tladesignz/IPtProxy), licensed under [MIT](https://github.com/tladesignz/IPtProxy/blob/master/LICENSE)
- [Eureka](https://github.com/xmartlabs/Eureka), licensed under [MIT](https://github.com/xmartlabs/Eureka/blob/master/LICENSE)
- [ImageRow] (https://github.com/EurekaCommunity/ImageRow), licensed under [MIT](https://github.com/EurekaCommunity/ImageRow/blob/master/LICENSE)
- [ProgressHUD](https://github.com/relatedcode/ProgressHUD), licensed under [MIT](https://github.com/relatedcode/ProgressHUD/blob/master/LICENSE)
- [MBProgressHUD-OSX](https://github.com/Foxnolds/MBProgressHUD-OSX), licensed under [MIT](https://github.com/Foxnolds/MBProgressHUD-OSX/blob/master/LICENSE)
- [ReachabilitySwift](https://github.com/ashleymills/Reachability.swift), licensed under [MIT] (https://github.com/ashleymills/Reachability.swift/blob/master/LICENSE))

## Author

Benjamin Erhart, berhart@netzarchitekten.com
for the [Guardian Project](https://guardianproject.info)

## License

IPtProxyUI is available under the MIT license. See the LICENSE file for more info.
