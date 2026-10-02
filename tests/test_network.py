import os
import socket

import pytest
import requests


@pytest.mark.private
@pytest.mark.skipif(
    not os.environ.get("RUN_PRIVATE_ACR_TESTS", "").lower() in {"1", "true", "yes"},
    reason="Private registry checks run only when RUN_PRIVATE_ACR_TESTS=true",
)
def test_private_acr_dns_and_http():
    acr_name = "westeuropeprodacr01"
    fqdn = f"{acr_name}.azurecr.io"
    addrs = socket.getaddrinfo(fqdn, 443, proto=socket.IPPROTO_TCP)
    ips = sorted({item[4][0] for item in addrs if item[4]})
    assert ips, f"No DNS result for {fqdn}"
    assert all(ip.startswith("10.40.0.") for ip in ips)

    resp = requests.get(f"https://{fqdn}/v2/", timeout=15)
    assert resp.status_code == 401
