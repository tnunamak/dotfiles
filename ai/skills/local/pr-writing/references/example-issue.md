Each time a connector reports a checkpoint for a stream, the runtime appends a `run.state_staged` event to `spine_events` with the stream's entire cursor in `data_json`. When the run succeeds it appends a `run.state_advanced` event carrying the same cursor again (`reference-implementation/runtime/index.ts`: `handleStateMessage` near line 5120, and the advance path near line 4531). Neither event is ever read for its cursor; the committed value lives in connector state. So for a connector with a large cursor, every checkpoint writes two more copies of it into the log, and nothing compacts them afterwards.

On an instance with five months of sync history, `spine_events` had grown to 34 GB. Measured with `pg_column_size(data_json)` per event type:

| event type | rows | payload |
| --- | --- | --- |
| `run.state_staged` | 163,281 | 16 GB |
| `run.state_advanced` | 96,546 | 15 GB |
| next largest type | | 146 MB |

Two connectors produced almost all of it: one whose cursor is about 700 KB (39,000 rows, 25 GB) and one whose cursor is about 1.3 MB (3,300 rows, 4 GB).

Proposal: record the cursor's SHA-256 and byte size in these events instead of the cursor itself, next to the stream name and commit intent they already carry. A one-off migration can rewrite the existing rows the same way, and a `VACUUM FULL` afterwards should return most of the 31 GB.

Not verified: I found no reader of `data_json.cursor` outside the console timeline and the vendored operator UI, but I did not trace the MCP server or the CLI. Whether a 700 KB cursor is reasonable for that connector is a separate data-connectors question.
