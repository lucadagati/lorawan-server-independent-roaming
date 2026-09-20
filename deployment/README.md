# deployment

Single-container stack (ChirpStack v3 Network Server + Application Server
+ Gateway Bridge + PostgreSQL + Redis + Mosquitto + LWN-Simulator) used to
reproduce a test network without physical gateways/devices. Build from the
repository root, not from this directory, because the `Dockerfile` (at the
repo root) also needs `simulator-patch/`:

```sh
docker build -t lorawan-roaming-demo -f Dockerfile .
```

At first start, `bootstrap_chirpstack.sh` creates a demo user
(`demo@local` / `demo`) and seeds ChirpStack from the LWN-Simulator config
in `lwnsimulator_demo/` — one virtual gateway and two ABP devices at
Università degli Studi di Messina (38.26°N, 15.59°E). Ports: 8080
(ChirpStack UI), 9000 (LWN-Simulator UI), 1883 (MQTT).

`run_lwn.sh` / `run_lwn_delayed.sh` start the simulator immediately or
after a delay (useful when other services need time to come up first
inside the same container under supervisord).
