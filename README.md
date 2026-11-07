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

## How it works (30-second version)

```
 device ──radio──► FOREIGN gateway ─► foreign MQTT broker (127.0.0.1)
                                          │  gateway/<foreign-gw-id>/event/up
                                          ▼
                              roaming bridge (gwaddons.py)
                         1. decode DevAddr from the PHYPayload
                         2. look it up in roamingdb.json  → (home NS IP, home GatewayID)
                         3. rewrite every "gatewayID" in the JSON with the home GatewayID
                         4. publish on the HOME broker, topic gateway/<home-gw-id>/event/up
                                          │
                                          ▼
                    home ChirpStack Network Server (sees a "normal" uplink)
```

## Requirements

| Need | Version / note |
|---|---|
| Docker | to build the all-in-one demo stack (ChirpStack v3, Mosquitto, PostgreSQL, Redis, LWN-Simulator); needs Internet access at build time |
| Python | 3.8+ for the bridge (`paho-mqtt<2`, `termcolor`, `tinydb`) |
| Mosquitto clients | optional, for `mosquitto_pub/sub` experiments |

## Step-by-step guide

### 1. Test the bridge logic (no network needed)

```sh
cd roaming-bridge/python
python3 -m venv .venv && . .venv/bin/activate
pip install -r requirements.txt pytest
python -m pytest -q tests          # 3 tests: DevAddr decoding, gatewayID rewriting, roaming-table lookup
```

### 2. Bring up a ChirpStack v3 + LWN-Simulator test network

```sh
docker build -t lorawan-roaming-demo .
docker run -it --rm -p 8080:8080 -p 9000:9000 -p 1883:1883 lorawan-roaming-demo
```

On first start the container creates a demo user (`demo@local` / `demo`) and seeds one virtual gateway and two ABP devices located at the University of Messina (details in [`deployment/README.md`](deployment/README.md)). Open the ChirpStack UI at <http://localhost:8080> and the simulator UI at <http://localhost:9000>.

### 3. Configure the roaming table

Copy the example and put one row per roaming device:

```sh
cd roaming-bridge/python
cp roamingdb.example.json roamingdb.json
```

| Field | Meaning |
|---|---|
| `device_address` | DevAddr of the roaming device, 8 lowercase hex digits (`26011bda`) |
| `ns_ip` | address of the **home** network's MQTT broker/Network Server |
| `roaming_gw_id` | GatewayID (16 hex digits) of a gateway already registered on the home network |

### 4. Run the bridge on the foreign side

```sh
cd roaming-bridge/python
export ROAMING_LOCAL_BROKER=127.0.0.1      # broker the foreign gateway publishes to (default)
export ROAMING_DB_PATH=roamingdb.json      # roaming table (default)
python3 gwaddons.py
```

Uplinks from known DevAddrs are forwarded (`Forwarded gateway/<foreign>/event/up -> <ns_ip>/gateway/<home>/event/up` in green); unknown DevAddrs are dropped with a yellow message.

### 5. Inject a test uplink

With a Mosquitto broker on `127.0.0.1` and the table above:

```sh
mosquitto_pub -h 127.0.0.1 -t gateway/aaaaaaaaaaaaaaaa/event/up \
  -m '{"phyPayload":"QNobASYAAAAAAAABAAAAAA==","rxInfo":[{"gatewayID":"aaaaaaaaaaaaaaaa","rssi":-40}]}'
```

The payload encodes DevAddr `26011bda`; the bridge republishes it on `<ns_ip>` under `gateway/de2b5906b8e2ca64/event/up` with `gatewayID` rewritten. Watch it with `mosquitto_sub -h <ns_ip> -t 'gateway/#' -v` (helpers in [`mqtt-debug-scripts/`](mqtt-debug-scripts/)).

### 6. Reproduce the measurements (optional)

1. Provision many devices: [`device-provisioning/`](device-provisioning/) (`CHIRPSTACK_AS_URL`, `CHIRPSTACK_API_TOKEN`, `CHIRPSTACK_DEVICE_PROFILE_ID` must be set; the scripts take the device count as argument).
2. Capture timestamps/sequence numbers with the `mqtt-debug-scripts/`, then reduce them with the pipelines in [`stats/`](stats/) (mean/variance of latency).
3. For scalability runs apply the Prometheus patch in [`simulator-patch/`](simulator-patch/) to LWN-Simulator (the Dockerfile already does this).

## Configuration reference

| Variable | Used by | Default | Purpose |
|---|---|---|---|
| `ROAMING_LOCAL_BROKER` | `gwaddons.py` | `127.0.0.1` | local (visited-network) MQTT broker |
| `ROAMING_DB_PATH` | `gwaddons.py` | `roamingdb.json` | TinyDB roaming table |
| `CHIRPSTACK_AS_URL`, `CHIRPSTACK_API_TOKEN`, `CHIRPSTACK_APPLICATION_ID`, `CHIRPSTACK_DEVICE_PROFILE_ID` | `device-provisioning/*.sh` | — (`APPLICATION_ID`=1) | ChirpStack v3 REST access |
| `CHIRPSTACK_DEMO_EMAIL`, `CHIRPSTACK_DEMO_PASSWORD` | `deployment/bootstrap_chirpstack.sh` | `demo@local` / `demo` | demo account created in the container |

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| Bridge prints `DevAddr ... is not a known roaming device, dropping` | the DevAddr is missing from `roamingdb.json` or has uppercase letters/wrong length |
| `ModuleNotFoundError: paho` or `TypeError` when creating `mqtt.Client()` | install `paho-mqtt<2` (version 2 changed the constructor) |
| Nothing is forwarded | check the foreign gateway really publishes on the broker in `ROAMING_LOCAL_BROKER` and that the home broker accepts anonymous/the bridge's connections |
| Home NS ignores the packet | `roaming_gw_id` must be a gateway registered on the home network, and the device must be activated there with matching keys/FCnt |
| Docker build fails while fetching packages | the image downloads ChirpStack, Go and LWN-Simulator at build time: check Internet access and upstream availability |

## Limitations and security

- The mechanism is intentionally a *gateway-attribution rewrite*: RSSI/SNR/location no longer describe the real reception point and whoever controls the bridge can attribute traffic to any home GatewayID it knows. Read [`docs/architecture.md`](docs/architecture.md) and [`docs/as-built-vs-paper.md`](docs/as-built-vs-paper.md).
- The REST activation API, SLA/ACL handshake and Golang gateway-bridge integration described in the paper are **not** part of this repository.
- Stats/keep-alive topics are not forwarded (see `gwaddons.py`).
- Test devices use sequential or well-known keys: never reuse them in production.
- Verified: unit tests of the bridge helpers; the Docker image builds on Ubuntu 22.04 and starts (ChirpStack UI on 8080, LWN-Simulator UI on 9000, demo bootstrap completes).
- Not verified in this environment: end-to-end forwarding between two live ChirpStack networks.

## Changes in this revision

- `decode_dev_addr` corrected (bytes 1-4 of the frame, byte-reversed); unit tests added.
- Bridge paths/brokers configurable via environment variables.
- Dockerfile fixed: base image pinned to Ubuntu 22.04 (`ubuntu:latest` no longer ships `apt-key`), ChirpStack repository key installed through a signed keyring, and the LWN-Simulator Prometheus patch made optional because it no longer applies to upstream `master` (see `simulator-patch/README.md`).

## License

See [`LICENSE`](LICENSE).
