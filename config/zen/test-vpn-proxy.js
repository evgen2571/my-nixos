// node config/zen/test-vpn-proxy.js /path/to/generated.pac
const assert = require("node:assert/strict");
const fs = require("node:fs");
const vm = require("node:vm");
const context = vm.createContext({});
vm.runInContext(fs.readFileSync(process.argv[2], "utf8"), context);
for (const host of ["example.com", "www.example.com", "a.b.example.com", "EXAMPLE.COM."]) {
  assert.equal(context.FindProxyForURL(`https://${host}/`, host), "SOCKS5 127.0.0.1:1080");
}
for (const host of ["example.org", "notexample.com", "example.com.evil.test", "localhost", "127.0.0.1", "::1"]) {
  assert.equal(context.FindProxyForURL(`https://${host}/`, host), "DIRECT");
}
console.log("PAC domain, subdomain, boundary, case, and trailing-dot checks passed");
