"""Unit tests for the pure helpers of the roaming bridge (no MQTT broker needed)."""
import base64
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import gwaddons  # noqa: E402


def make_phy_payload(dev_addr_le_hex: str) -> str:
    """Build a minimal PHYPayload: MHDR + DevAddr(4 bytes, little endian) + padding."""
    raw = bytes.fromhex("40" + dev_addr_le_hex + "00000000000000")
    return base64.b64encode(raw).decode()


def test_decode_dev_addr_roundtrip():
    # A DevAddr is transmitted little-endian: bytes da 1b 01 26 -> 26011bda
    payload = make_phy_payload("da1b0126")
    assert gwaddons.decode_dev_addr(payload) == "26011bda"


def test_rewrite_key_replaces_nested_and_top_level():
    msg = {"gatewayID": "aaaa", "rxInfo": [{"gatewayID": "aaaa", "rssi": -40}], "x": {"y": {"gatewayID": "aaaa"}}}
    gwaddons.rewrite_key(msg, "gatewayID", "bbbb")
    assert json.dumps(msg).count("aaaa") == 0
    assert msg["rxInfo"][0]["rssi"] == -40


def test_lookup_roaming_target(tmp_path, monkeypatch):
    from tinydb import TinyDB
    db_path = tmp_path / "roamingdb.json"
    TinyDB(str(db_path)).insert({"device_address": "26011bda", "ns_ip": "10.0.0.10", "roaming_gw_id": "de2b5906b8e2ca64"})
    monkeypatch.setattr(gwaddons, "ROAMING_DB_PATH", str(db_path))
    assert gwaddons.lookup_roaming_target("26011bda") == ("10.0.0.10", "de2b5906b8e2ca64")
    assert gwaddons.lookup_roaming_target("deadbeef") is None
