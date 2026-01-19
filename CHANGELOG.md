# IPtProxyUI

## 5.0.0
- Updated to IPtProxy 5.0.0 therefore Lyrebird 0.8.1.
- Added forwarding of new transport connection and error events using notifications.
- Replaced `print` with proper logging.

## 4.10.0
- Set minimal deployment target of iOS to 15.0 which is mandatory since Xcode 16. Ooops.
- Updated dependencies to IPtProxy 4.3.0, which contains latest Lyrebird 0.8.0.
- Updated translations.

## 4.9.2
- Added support for proxies.

## 4.9.1
- Improved accessibility with VoiceOver.
- Updated to Xcode 26.

## 4.9.0
- Followed Tor Project's switch from "meek-azure" to "meek"
- Improved bridge parsing and construction. Added support for vanilla bridges.
- Updated translations.

## 4.8.1
- Updated translations.
- Added a `Transport.stopAllOthers()` method.
- Added support for a `Bridge.utls` property.
- Make sure, pseudo-IP addresses of Snowflake AMP bridges are, as they are expected.
- Added support for eventually existing default webtunnel bridges.

## 4.8.0
- Updated to IPtProxy version 4.2.0 containing Lyrebird 0.6.1 and Snowflake 2.11.0.
- Updated translations.

## 4.7.0
- Updated to IPtProxy version 4.0.0 containing Lyrebird 0.5.0 and Snowflake 2.10.1.
- Updated translations.

## 4.6.2
- Allow injection of `onDemandBridges` and `customBridges` lists when creating the Tor configuration.
  IPtProxyUI might be unable to read them with its own `Settings` implementation.

## 4.6.1
- Updated translations.
- Added support for mixed custom bridges.

## 4.6.0
- Updated to IPtProxy version 3.8.1 containing Lyrebird 0.2.0.
- Added Webtunnel support.

## 4.5.0
- Updated to IPtProxy version 3.7.0 containing Snowflake 2.9.2.
- Updated Indonesian translation.

## 4.4.0
- Updated to IPtProxy version 3.6.0 containing Snowflake 2.9.1.

## 4.3.1
- Replaced fastly.net as domain front. Updated built-in bridges list.

## 4.3.0
- Updated to IPtProxy version 3.4.0 containing Snowflake 2.8.1.
- Updated translations.


## 4.2.1
- Added handling of doubled fingerprint in bridge lines. Seems important for Snowflake.

## 4.2.0
- Updated to IPtProxy version 3.3.0 containing Snowflake 2.8.0.
- Fixed auto-config under macOS.

## 4.1.3
- Downgraded Eureka dependency to 5.3, since 5.4 isn't really needed, and other projects still need to stick to 5.3.

## 4.1.2
- Fixed Snowflake AMP support. Snowflake now honors configuration from the bridge line, so we need to modify that.
- Improved Snowflake support in certain countries.

## 4.1.1
- Fixed mixed-up Snowflake arguments.

## 4.1.0
- Updated to IPtProxy version 3.2.1 containing Snowflake 2.7.0
- Updated translations.
- Minor cleanup.
- Added another front domain which might work better in certain countries using Snowflake's 
  new support for multiple front domains.

## 4.0.0
- Removed manual configuration with CAPTCHA, as that was recently deprecated by Tor Project.
- Improved automatic configuration:
  - Update built-in bridges automatically.
  - Store custom Obfs4 bridges, when provided, even when recommendation is to use something else.
- Re-added Meek Azure, as specific people have a lot of trouble on other bridge types and it still didn't get removed. 
- Updated translations.
- Updated default bridges list.

## 3.0.2
- Updated translations.
- Updated default bridges list.

## 3.0.1
- Fixed `AppEx` subspec. `ProgressHUD` cannot be used in app extensions.

## 3.0.0
- Updated to latest IPtProxy containing Lyrebird 0.1.0 (Tor fork of Obfs4proxy) and Snowflake 2.6.0.
- Updated default bridges list.
- Updated translations.
- Fixed dependencies which inhibited release with latest Xcode 14.3:
  - Inlined `ReachabilitySwift` dependency.
  - Replaced `MBProgressHUD` with `ProgressHUD`.
- Updated minimum iOS version to 13.0 due to new `ProgressHUD` dependency.

## 2.1.1
- Added example project for easier development.
- Updated default bridges list.
- Updated translations.

## 2.1.0
- Replaced hardcoded Snowflake configuration with configuration from Tor Project's
  bridge configuration API, which now contains 2(!) Snowflake bridges.
- Updated default bridges list.
- Updated translations.

## 2.0.0
- Updated to IPtProxy 2.0.0 which has it's API changed. You will now need to 
  define a `TOR_PT_STATE_LOCATION` directory voluntarily before using any transport, 
  either through `IPtProxy.setStateLocation()` or through 
  `IPtProxyUI.Settings.stateLocation`!
- Updated default Obfs4 bridges list.
- Updated Snowflake STUN server list.

## 1.11.0
- Added Telegram Bot support.
- Updated default Obfs4 bridges list.
- Updated translations.
- Reorganized code for easier reuse.
Contains minimal breaking changes!

## 1.10.5
- Updated to IPtProxy 1.9.0.
- Updated default Obfs4 bridges list.

## 1.10.4
- Updated Icelandic, Macedonian and simplified Chinese translations.
- Updated STUN server list for Snowflake.
- Updated default Obfs4 bridges list.
- Fixed minor warning.

## 1.10.3
- Updated to IPtProxy 1.8.1.
- Added logging support.
- Updated Croatian translation.
- Updated built-in Obfs4 bridges list.

## 1.10.2
- Updated locale strings.

## 1.10.1
- Updated locale strings.

## 1.10.0
- Added Khmer translation.
- Updated Icelandic, Brazilian Portuguese and Russian translations.
- Fixed script test dummy file name.
- Fixed minor issue when custom bridges where selected but not changed in macOS version.
- Support macOS 11 (Big Sur). 

## 1.9.0
- Fixed issues with Xcode 14.
- Added MacOS support.

## 1.8.5
- Fixed crash in `MeekURLProtocol`.
- Updated Albanian and Japanese translation.  

## 1.8.4
- Updated Farsi, Hebrew and Ukrainian translation.

## 1.8.3
- Updated French, Russian and Spanish translation.

## 1.8.2
- Updated Bengali, Farsi, French, Hebrew, Russian and Turkish translation.
- Removed a translation string, improved wording for some.

## 1.8.1
- Fixed copy-paste bug regarding success checkmark icon.

## 1.8.0
- Updated Arabic, Czech and Russian translation.
- Updated built-in bridges list.
- Fixed UI bug when selected transport changed.
- Added automatic configuration support via Moat's new "circumvention settings" API.

## 1.7.5
- Updated simplified Chinese, Dutch, Icelandic, Macedonian, Spanish, Thai, Ukrainian translation.
- Added Romanian translation. 

## 1.7.4
- Updated Croatian and Hebrew translation.
- Updated update-bridges script.

## 1.7.3
- Updated Albanian, Farsi, French, Russian, Turkish and Ukrainian translation.
- Improved screenshot automation.

## 1.7.2
- Improved accessibility.
- Updated traditional Chinese translation.
- Updated Korean translation.

## 1.7.1
- Updated Chinese translation.
- Added Khmer translation.

## 1.7.0
- Updated to IPtProxy 1.5.0 containing Snowflake 2.1.0 and Obfs4proxy 0.0.13.
- Updated Chinese translation.

## 1.6.0
- Updated translations.
- Updated to IPtProxy 1.4.0.
- Updated built-in Obfs4 bridges list.

## 1.5.0
- Updated translations.
- Updated to IPtProxy 1.3.0.
- Added Snowflake AMP rendezvous support.
- Updated built-in Obfs4 bridges list.

## 1.4.0
- Updated translations.
- Added `IpSupport` class to help improve support of IPv6-only networks.

## 1.3.0
- Updated translations.
- Added a default `Settings` implementation for selected transport and custom bridges.

## 1.2.0
- BREAKING CHANGE: Improved naming. 

## 1.1.0
- More translations.
- Various small fixes.
- Improved overridability.

## 1.0.0

- Initial release.
