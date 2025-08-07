import XCTest
import IPtProxyUI

class Tests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testBridgeParsing() {
		var b = Bridge("meek_lite 192.0.2.20:80 url=https://1603026938.rsc.cdn77.org front=www.phpmyadmin.net utls=HelloRandomizedALPN")

		XCTAssertEqual(b.description, "[Bridge] raw=meek_lite 192.0.2.20:80 url=https://1603026938.rsc.cdn77.org front=www.phpmyadmin.net utls=HelloRandomizedALPN, transport=meek_lite, ip=192.0.2.20, port=80, fingerprint1=(nil), fingerprint2=(nil), url=https://1603026938.rsc.cdn77.org, front=www.phpmyadmin.net, fronts=[], cert=(nil), iatMode=-1, ice=(nil), utls=HelloRandomizedALPN, utlsImitate=(nil), ver=(nil)")

		var builder = Bridge.Builder(transport: "meek_lite", ip: "192.0.2.20", port: 80, fingerprint1: "")
		builder.url = URL(string: "https://1603026938.rsc.cdn77.org")
		builder.front = "www.phpmyadmin.net"
		builder.utls = "HelloRandomizedALPN"

		XCTAssertEqual(builder.build().raw, b.raw)


		b = Bridge("obfs4 45.145.95.6:27015 C5B7CD6946FF10C5B3E89691A7D3F2C122D2117C cert=TD7PbUO0/0k6xYHMPW3vJxICfkMZNdkRrb63Zhl5j9dW3iRGiCx0A7mPhe5T2EDzQ35+Zw iat-mode=0")

		XCTAssertEqual(b.description, "[Bridge] raw=obfs4 45.145.95.6:27015 C5B7CD6946FF10C5B3E89691A7D3F2C122D2117C cert=TD7PbUO0/0k6xYHMPW3vJxICfkMZNdkRrb63Zhl5j9dW3iRGiCx0A7mPhe5T2EDzQ35+Zw iat-mode=0, transport=obfs4, ip=45.145.95.6, port=27015, fingerprint1=C5B7CD6946FF10C5B3E89691A7D3F2C122D2117C, fingerprint2=(nil), url=(nil), front=(nil), fronts=[], cert=TD7PbUO0/0k6xYHMPW3vJxICfkMZNdkRrb63Zhl5j9dW3iRGiCx0A7mPhe5T2EDzQ35+Zw, iatMode=0, ice=(nil), utls=(nil), utlsImitate=(nil), ver=(nil)")

		builder = Bridge.Builder(transport: "obfs4", ip: "45.145.95.6", port: 27015, fingerprint1: "C5B7CD6946FF10C5B3E89691A7D3F2C122D2117C")
		builder.cert = "TD7PbUO0/0k6xYHMPW3vJxICfkMZNdkRrb63Zhl5j9dW3iRGiCx0A7mPhe5T2EDzQ35+Zw"
		builder.iatMode = 0

		XCTAssertEqual(builder.build().raw, b.raw)


		b = Bridge("snowflake 192.0.2.4:80 8838024498816A039FCBBAB14E6F40A0843051FA fingerprint=8838024498816A039FCBBAB14E6F40A0843051FA url=https://1098762253.rsc.cdn77.org/ fronts=www.cdn77.com,www.phpmyadmin.net ice=stun:stun.antisip.com:3478,stun:stun.epygi.com:3478,stun:stun.uls.co.za:3478,stun:stun.voipgate.com:3478,stun:stun.mixvoip.com:3478,stun:stun.nextcloud.com:3478,stun:stun.bethesda.net:3478,stun:stun.nextcloud.com:443 utls-imitate=hellorandomizedalpn")

		XCTAssertEqual(b.description, "[Bridge] raw=snowflake 192.0.2.4:80 8838024498816A039FCBBAB14E6F40A0843051FA fingerprint=8838024498816A039FCBBAB14E6F40A0843051FA url=https://1098762253.rsc.cdn77.org/ fronts=www.cdn77.com,www.phpmyadmin.net ice=stun:stun.antisip.com:3478,stun:stun.epygi.com:3478,stun:stun.uls.co.za:3478,stun:stun.voipgate.com:3478,stun:stun.mixvoip.com:3478,stun:stun.nextcloud.com:3478,stun:stun.bethesda.net:3478,stun:stun.nextcloud.com:443 utls-imitate=hellorandomizedalpn, transport=snowflake, ip=192.0.2.4, port=80, fingerprint1=8838024498816A039FCBBAB14E6F40A0843051FA, fingerprint2=8838024498816A039FCBBAB14E6F40A0843051FA, url=https://1098762253.rsc.cdn77.org/, front=(nil), fronts=[\"www.cdn77.com\", \"www.phpmyadmin.net\"], cert=(nil), iatMode=-1, ice=stun:stun.antisip.com:3478,stun:stun.epygi.com:3478,stun:stun.uls.co.za:3478,stun:stun.voipgate.com:3478,stun:stun.mixvoip.com:3478,stun:stun.nextcloud.com:3478,stun:stun.bethesda.net:3478,stun:stun.nextcloud.com:443, utls=(nil), utlsImitate=hellorandomizedalpn, ver=(nil)")

		builder = Bridge.Builder(transport: "snowflake", ip: "192.0.2.4", port: 80, fingerprint1: "8838024498816A039FCBBAB14E6F40A0843051FA")
		builder.fingerprint2 = "8838024498816A039FCBBAB14E6F40A0843051FA"
		builder.url = URL(string: "https://1098762253.rsc.cdn77.org/")
		builder.fronts = ["www.cdn77.com", "www.phpmyadmin.net"]
		builder.ice = "stun:stun.antisip.com:3478,stun:stun.epygi.com:3478,stun:stun.uls.co.za:3478,stun:stun.voipgate.com:3478,stun:stun.mixvoip.com:3478,stun:stun.nextcloud.com:3478,stun:stun.bethesda.net:3478,stun:stun.nextcloud.com:443"
		builder.utlsImitate = "hellorandomizedalpn"

		XCTAssertEqual(builder.build().raw, b.raw)


		b = Bridge("webtunnel [2001:db8:1178:dc13:afaf:da8e:f592:398a]:443 07C77888D2367C25CA875E2174D9B225140940E9 url=https://nextcloud.privacy-vbox.de/iJmug5bRcsKeVv45h7a0fvkM ver=0.0.2")

		XCTAssertEqual(b.description, "[Bridge] raw=webtunnel [2001:db8:1178:dc13:afaf:da8e:f592:398a]:443 07C77888D2367C25CA875E2174D9B225140940E9 url=https://nextcloud.privacy-vbox.de/iJmug5bRcsKeVv45h7a0fvkM ver=0.0.2, transport=webtunnel, ip=[2001:db8:1178:dc13:afaf:da8e:f592:398a], port=443, fingerprint1=07C77888D2367C25CA875E2174D9B225140940E9, fingerprint2=(nil), url=https://nextcloud.privacy-vbox.de/iJmug5bRcsKeVv45h7a0fvkM, front=(nil), fronts=[], cert=(nil), iatMode=-1, ice=(nil), utls=(nil), utlsImitate=(nil), ver=0.0.2")

		builder = Bridge.Builder(transport: "webtunnel", ip: "[2001:db8:1178:dc13:afaf:da8e:f592:398a]", port: 443, fingerprint1: "07C77888D2367C25CA875E2174D9B225140940E9")
		builder.url = URL(string: "https://nextcloud.privacy-vbox.de/iJmug5bRcsKeVv45h7a0fvkM")
		builder.ver = "0.0.2"

		XCTAssertEqual(builder.build().raw, b.raw)


		b = Bridge("217.83.162.43:9001 6F1D1B83152D6181CAC2C726EB7547B7B9BB7B7F")

		XCTAssertEqual(b.description, "[Bridge] raw=217.83.162.43:9001 6F1D1B83152D6181CAC2C726EB7547B7B9BB7B7F, transport=(nil), ip=217.83.162.43, port=9001, fingerprint1=6F1D1B83152D6181CAC2C726EB7547B7B9BB7B7F, fingerprint2=(nil), url=(nil), front=(nil), fronts=[], cert=(nil), iatMode=-1, ice=(nil), utls=(nil), utlsImitate=(nil), ver=(nil)")

		builder = Bridge.Builder(ip: "217.83.162.43", port: 9001, fingerprint1: "6F1D1B83152D6181CAC2C726EB7547B7B9BB7B7F")

		XCTAssertEqual(builder.build().raw, b.raw)
    }
}
