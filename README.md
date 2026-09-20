# lorawan-server-independent-roaming

Reference implementation of the server-independent LoRaWAN roaming
mechanism described in:

> L. D'Agati, L. García, R. Asorey-Cacheda, M. Garofalo, F. Longo,
> A.-J. Garcia-Sanchez, J. Garcia-Haro, A. Puliafito, G. Merlino,
> "Seamless Remote Roaming Activation in LoRaWAN via an API-driven Gateway
> Bridge Service", Journal of Network and Computer Applications.

Roaming devices on LoRaWAN 1.0 networks can only be forwarded by gateways
that belong to their own network, or by gateways their network operator has
a bilateral agreement with. This project lets a device be forwarded through
an unrelated, unregistered gateway by rewriting the gateway attribution at
the MQTT layer before the packet reaches the home Network Server — see
[`docs/architecture.md`](docs/architecture.md) for how, and its tradeoffs.

## What's here

| Directory | Contents |
|---|---|
| [`roaming-bridge/`](roaming-bridge/) | The Python MQTT bridge that performs the roaming forwarding, plus its earlier iterations. |
| [`device-provisioning/`](device-provisioning/) | Scripts to bulk-provision ABP test devices on ChirpStack and LWN-Simulator. |
| [`mqtt-debug-scripts/`](mqtt-debug-scripts/) | Small MQTT subscribe helpers used during development. |
| [`stats/`](stats/) | Shell pipelines that reduce raw MQTT subscribe logs to the latency mean/variance figures used in the paper. |
| [`deployment/`](deployment/) | Single-container ChirpStack v3 + LWN-Simulator stack for reproducing a test network. |
| [`simulator-patch/`](simulator-patch/) | Prometheus instrumentation patch for LWN-Simulator, used for the scalability figures. |
| [`reference/`](reference/) | Pre-paper design notes and architecture sketch. |
| [`docs/`](docs/) | Architecture writeup and an honest diff against what the published paper describes. |

## History

This repository replaces four separate, unmaintained repositories
(`Chirpstack_BackEnd`, `chirpstack-gateway-bridge`, `GW_LoRa_Roaming`, and a
fork of `LWN-Simulator`), consolidated here with a consistent structure and
documentation. **Read [`docs/as-built-vs-paper.md`](docs/as-built-vs-paper.md)
before assuming any part of this matches the paper's Algorithm 1 line for
line** — several pieces described there (the REST activation API, the
SLA/ACL handshake, the Golang Gateway Bridge integration) were not found in
any of the source repositories and are not present here either.

## Quick start

```sh
# 1. Bring up ChirpStack v3 + LWN-Simulator in one container
docker build -t lorawan-roaming-demo .
docker run -it --rm -p 8080:8080 -p 9000:9000 -p 1883:1883 lorawan-roaming-demo

# 2. Provision the roaming device table used by the bridge
#    (edit roaming-bridge/python/roamingdb.json manually, or adapt
#    device-provisioning/add_device_to_chirpstack.sh)

# 3. Run the bridge on the "foreign" gateway
cd roaming-bridge/python
pip install -r requirements.txt
python3 gwaddons.py
```

## License

See [`LICENSE`](LICENSE).
