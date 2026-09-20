# stats

Shell pipelines used to reduce raw `mosquitto_sub` capture logs
(timestamp + sequence number pairs, one file per direction: sent vs.
received) into the latency mean/standard-deviation figures reported in the
paper's experimental sections.

- `roaming/` — pipelines for the roaming-device captures.
- `proposed/` — pipelines for the stationary/home-device captures used as
  the baseline comparison.
- `fifo-pipeline/` — a two-stage producer/consumer pair connected through a
  named pipe, used to stream one of the above computations live instead of
  batch-processing a finished log file.

These all expect specific input filenames (`sub_sort.txt`, `send_sort.txt`,
etc.) produced by the `mqtt-debug-scripts/` captures; check each script's
`paste`/`awk` invocation before pointing it at your own logs.
