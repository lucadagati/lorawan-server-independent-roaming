# LWN-Simulator instrumentation patch

The paper's scalability results (Section "Scalability and Performance
Analysis Using LWN-Simulator", figures `avg_latency_over_FCnt*`) were
produced with [UniCT-ARSLab/LWN-Simulator](https://github.com/UniCT-ARSLab/LWN-Simulator)
(the simulator cited in the paper) plus one instrumentation change: Prometheus
counters for uplinks sent, downlinks received, and ACK timeouts, added to
`simulator/components/device/functionality.go`.

That change was originally committed directly to a private fork
(`lucadagati/LWN-Simulator`) instead of being kept as a patch. It's
reproduced here as `0001-add-prometheus-uplink-downlink-metrics.patch` so it
can be applied on top of a clean checkout of the upstream simulator without
depending on that fork, which does not track upstream:

```sh
git clone https://github.com/UniCT-ARSLab/LWN-Simulator.git
cd LWN-Simulator
git apply ../0001-add-prometheus-uplink-downlink-metrics.patch
```

It requires `github.com/prometheus/client_golang` as an added dependency
(`go get github.com/prometheus/client_golang/prometheus` before building).

This patch only adds counters; it does not change simulated device
behavior, so simulation results are unaffected by whether it's applied.
