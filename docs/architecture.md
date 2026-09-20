# Architecture

Reference: L. D'Agati et al., "Seamless Remote Roaming Activation in
LoRaWAN via an API-driven Gateway Bridge Service", Journal of Network and
Computer Applications (see `reference/` for design notes predating the
paper).

## The mechanism

A LoRaWAN end device is activated (ABP) on its home network and normally
transmits through gateways belonging to that network. When it roams out of
range of its home gateways and is only reachable by a "foreign" gateway
belonging to a different, unrelated LoRaWAN network, that foreign network's
Network Server has no reason to accept or forward the packet — it doesn't
recognize the DevAddr, and there's no roaming agreement between the two
networks (LoRaWAN 1.0 has none of the passive/handover roaming machinery
that 1.1 defines).

The bridge in this repo (`roaming-bridge/`) sits on the foreign gateway,
between the physical radio and its own network's MQTT broker. It:

1. Subscribes to the raw `gateway/+/event/up` topic (the ChirpStack Gateway
   Bridge's normal output).
2. Decodes the DevAddr straight out of the PHYPayload (no need to fully
   parse or decrypt the LoRaWAN frame — the MIC/AppSKey are never touched).
3. Looks up the DevAddr in a local table to find which home network (NS
   IP) and which of *that home network's own, already-registered*
   GatewayIDs to use.
4. Rewrites the `gatewayID` field(s) in the message envelope to that home
   GatewayID, and republishes the (otherwise untouched) packet directly on
   the home network's MQTT broker.

The home Network Server has no way to tell the difference between this and
a packet that arrived through one of its own physical gateways — the
GatewayID it sees is legitimate, just not the one that actually received
the radio signal. That substitution is the entire trick, and it's also its
main limitation: see `as-built-vs-paper.md` and the paper's own "Security
considerations" section for what that costs (RSSI/SNR/location metadata no
longer describe the real reception point; whoever controls the foreign
bridge can attribute any decodable uplink to any home GatewayID it knows
about).

## Repository layout

- `roaming-bridge/python/` — the bridge itself (current + historical
  iterations).
- `device-provisioning/` — bulk ABP device registration against ChirpStack
  and LWN-Simulator, used to populate test networks.
- `mqtt-debug-scripts/` — ad hoc MQTT subscribe helpers used while
  developing the bridge.
- `stats/` — the shell pipelines used to turn raw subscribe logs into the
  latency mean/variance numbers reported in the paper's experimental
  sections.
- `deployment/` — a single-container ChirpStack v3 + LWN-Simulator stack
  used to reproduce the test networks without physical hardware.
- `simulator-patch/` — the Prometheus counters added to LWN-Simulator to
  produce the scalability figures.
- `reference/` — pre-paper design material (SLA/roaming design note,
  architecture sketch).
