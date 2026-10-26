{ domains, port }:
''
  function FindProxyForURL(url, host) {
    host = host.toLowerCase().replace(/\.$/, "");
    var domains = ${builtins.toJSON domains};
    for (var i = 0; i < domains.length; i++) {
      if (host === domains[i] || host.endsWith("." + domains[i])) {
        return "SOCKS5 127.0.0.1:${toString port}";
      }
    }
    return "DIRECT";
  }
''
