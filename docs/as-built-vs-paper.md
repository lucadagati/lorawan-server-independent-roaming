# As-built vs. the paper

This repository consolidates the actual source that existed across four
separate repositories (`Chirpstack_BackEnd`, `chirpstack-gateway-bridge`,
`GW_LoRa_Roaming`, a fork of `LWN-Simulator`) into one. While doing that
consolidation, several gaps surfaced between what those repositories
contain and what "Seamless Remote Roaming Activation in LoRaWAN via an
API-driven Gateway Bridge Service" describes. Recorded here so nobody
(including future us) mistakes this repo for a 1:1 implementation of the
paper's pseudocode:

1. **No REST `/configure` API.** Algorithm 1 in the paper ("Enhanced MQTT
   Broker Integration for Roaming") describes an async HTTP listener with a
   `POST /configure` endpoint that writes broker/gateway details to the
   local database at runtime. None of the three script iterations
   (`roaming-bridge/python/history/`) or the consolidated
   `roaming-bridge/python/gwaddons.py` implement an HTTP server of any
   kind. Configuration is either hardcoded module-level constants
   (`gwaddons_final.py`) or a pre-populated TinyDB file the operator edits
   by hand (`gwaddons_v7.py`, and the consolidated version).

2. **No SLA / ACL handshake.** The paper's roaming-interaction description
   (Section 3.3, `ACLmodReq`/`ACLmodAck`) and the "Security considerations"
   section (JWT tokens signed by an operator-specific CA, mutual-TLS
   bootstrap for the TinyDB encryption key) describe an authorization
   handshake between the foreign bridge and the home broker. No code
   implementing that handshake was found in any of the four source
   repositories. The scripts here connect to the home MQTT broker with
   whatever credentials are in its client config, with no additional
   authorization step.

3. **No Golang integration into the ChirpStack Gateway Bridge.** Section 5
   of the paper reports separate latency results for a "script version"
   (Python) and a "Golang version...developed as an addition to the code
   of the Chirpstack Gateway Bridge". The `chirpstack-gateway-bridge` fork
   is a single-commit, unmodified import of `brocaar/chirpstack-gateway-bridge`
   v3 — it contains no roaming-related code. If the Golang version's source
   still exists, it wasn't in any of the four repositories collected here;
   it should be added under `roaming-bridge/golang/` if recovered.

4. **No DNS-based NetID→NS resolution.** Section 3.3 describes resolving
   the serving NS's IP address via a DNS query keyed on NetID. The actual
   scripts resolve the NS IP from a manually populated TinyDB row keyed on
   DevAddr instead — simpler, but it means the "no pre-established
   agreement" framing in the paper is doing more work than the code
   supports: something (a person, or a missing automated step) still has
   to seed the DevAddr → NS IP mapping before roaming works for a given
   device.

5. **A ChirpStack API key was committed in plaintext** in the original
   `Proposed_Script_Setup/Add_Device_to_Chirpstack.sh` and
   `Del_Device_from_Chirpstack.sh` (JWT `api_key_id`
   `f795254a-9c4e-44ed-b7de-99f1fb4f72fc`, issued 2022-11-01). It has been
   removed from `device-provisioning/*.sh` here (now read from
   `CHIRPSTACK_API_TOKEN`). If that key is still active on any ChirpStack
   instance, revoke/rotate it.

None of this invalidates the experimental results in the paper — the
latency/packet-loss numbers were presumably measured against whatever
version of the code was running at the time, and that exact version may no
longer exist. It does mean this repository should be read as "the
reference implementation of the core mechanism, reorganized," not as
"the exact artifact the paper's figures were generated from."
