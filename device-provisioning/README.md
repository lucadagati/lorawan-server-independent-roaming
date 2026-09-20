# device-provisioning

Bulk-provisioning helpers used to populate test networks with sequential
ABP devices (DevEUI/DevAddr/keys derived from a counter — fine for lab
testing, never use sequential/all-zero keys in a real deployment).

- `add_device_to_chirpstack.sh [count]` / `del_device_from_chirpstack.sh [count]`
  — register/delete devices via the ChirpStack v3 Application Server REST
  API. Require `CHIRPSTACK_AS_URL`, `CHIRPSTACK_API_TOKEN`, and
  `CHIRPSTACK_DEVICE_PROFILE_ID` in the environment (see the scripts).
- `add_device_to_lwn.sh` — generates a `tempNodes.json` fragment with the
  same devices, in LWN-Simulator's device format.
- `jsonbuilder_lwn.sh <count>` — parameterized variant of the above, used
  to generate the 50/100-device populations for the scalability tests.
