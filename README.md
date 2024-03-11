# IPtProxyUI

Tor + Pluggable Transports on iOS and macOS

[![Version](https://img.shields.io/cocoapods/v/IPtProxyUI.svg?style=flat)](https://cocoapods.org/pods/IPtProxyUI)
[![License](https://img.shields.io/cocoapods/l/IPtProxyUI.svg?style=flat)](https://cocoapods.org/pods/IPtProxyUI)
[![Platform](https://img.shields.io/cocoapods/p/IPtProxyUI.svg?style=flat)](https://cocoapods.org/pods/IPtProxyUI)

IPtProxyUI provides all things necessary to use the Pluggable Transports from the 
[IPtProxy](https://github.com/tladesignz/IPtProxy) library with Tor,
preferrably via [Tor.framework](https://github.com/iCepa/Tor.framework). 

It includes all necessary configuration, code to interact with Tor Project's MOAT/rdsys 
service to update the user's configuration and fetch lesser-known bridges and, of course, a 
ready-made UI to show to your users which can handle all of the above.

The UI is complete for your users to configure all aspects of the Transports.
However, you're not obliged to use it. You can create your own and use the lower-level code
only.

Additionally there's a helper class `IpSupport` which can aid in better supporting
IPv6-only networks which are common with some mobile network carriers.


## Installation

IPtProxyUI is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'IPtProxyUI'
```

## Getting Started

### All-in-one `TorManager`

For a headache-free start into the world of Tor on iOS and macOS, check out
the new [`TorManager` project](https://github.com/tladesignz/TorManager)!

### Do-it-yourself

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
- [ProgressHUD](https://github.com/relatedcode/ProgressHUD), licensed under [MIT](https://github.com/relatedcode/ProgressHUD/blob/master/LICENSE)
- [MBProgressHUD-OSX](https://github.com/Foxnolds/MBProgressHUD-OSX), licensed under [MIT](https://github.com/Foxnolds/MBProgressHUD-OSX/blob/master/LICENSE)
- [ReachabilitySwift](https://github.com/ashleymills/Reachability.swift), licensed under [MIT] (https://github.com/ashleymills/Reachability.swift/blob/master/LICENSE))


## Further reading

https://tordev.guardianproject.info


## Author

Benjamin Erhart, berhart@netzarchitekten.com
for the [Guardian Project](https://guardianproject.info)


## License

IPtProxyUI is available under the MIT license. See the LICENSE file for more info.
