# History

Verbatim copies of the three script iterations found in the original
`GW_LoRa_Roaming` repository, kept for provenance. None were renamed or
edited beyond the `.py` extension needed for them to be recognized as
Python source (the originals had no extension).

| File | Behavior |
|---|---|
| `gwaddons_v5.py` | Static two-GatewayID substitution (`weird_GW_ID` / `normal_GW_ID`), hand-written nested-field handling for `rxInfo.gatewayID`. |
| `gwaddons_v7.py` | Adds the TinyDB lookup (`roamingdb.json`, keyed by DevAddr) to resolve the home NS IP and GatewayID per device. |
| `gwaddons_final.py` | Generalizes the field rewrite into a recursive `modify_dict` walk, but drops the TinyDB lookup back to hardcoded globals (`NS_IP_ADDRESS`, `GWid`). This was the last version present in the source repo. |

The current `../gwaddons.py` combines the recursive rewrite from
`gwaddons_final.py` with the TinyDB lookup from `gwaddons_v7.py` — see its
module docstring. It intentionally does **not** forward `stats`/`conn`
messages (both `v5` and `v7` did, to a single hardcoded home gateway),
because with a per-DevAddr roaming table there is no longer a single
"the" home network to fan those out to. If you need that behavior, `v7` is
the closest reference.
