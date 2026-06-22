# Tokensmash Agent Tool Benchmark Card

Generated: 2026-06-11 15:07:29Z

## Summary

Primary metric: Codex provider-reported `total_token_usage.total_tokens` per successful task run.
Each row uses the paired baseline from the same result batch, task, and replicate.

| tool         | baseline tokens | tool tokens | improvement | model   | reasoning | task                           | oracle        | result |
| ------------ | --------------- | ----------- | ----------- | ------- | --------- | ------------------------------ | ------------- | ------ |
| context_mode | 1265375         | 643229      | +49.2%      | gpt-5.5 | low       | clawmeter-openai-path-recovery | go test ./... | pass   |
| headroom     | 1265375         | 591837      | +53.2%      | gpt-5.5 | low       | clawmeter-openai-path-recovery | go test ./... | pass   |
| rtk          | 1265375         | 696266      | +45.0%      | gpt-5.5 | low       | clawmeter-openai-path-recovery | go test ./... | pass   |
| semmap       | 999151          | 879352      | +12.0%      | gpt-5.5 | low       | clawmeter-openai-path-recovery | go test ./... | pass   |
| repomix      | 620319          | 1309307     | -111.1%     | gpt-5.5 | low       | clawmeter-openai-path-recovery | go test ./... | pass   |
| gitingest    | 620319          | 949669      | -53.1%      | gpt-5.5 | low       | clawmeter-openai-path-recovery | go test ./... | pass   |

## Token Breakdown

| tool         | baseline input | baseline output | baseline reasoning | tool input | tool output | tool reasoning | duration |
| ------------ | -------------- | --------------- | ------------------ | ---------- | ----------- | -------------- | -------- |
| context_mode | 1258470        | 6905            | 1354               | 638155     | 5074        | 860            | 139.2s   |
| headroom     | 1258470        | 6905            | 1354               | 585635     | 6202        | 1889           | 188.5s   |
| rtk          | 1258470        | 6905            | 1354               | 690399     | 5867        | 663            | 163.3s   |
| semmap       | 992354         | 6797            | 1663               | 873725     | 5627        | 938            | 172.9s   |
| repomix      | 614125         | 6194            | 1178               | 1302926    | 6381        | 1162           | 204.3s   |
| gitingest    | 614125         | 6194            | 1178               | 943227     | 6442        | 1406           | 179.0s   |

## Evaluation Card

- **suite:** clawmeter-codex-all-tools
- **agent:** Codex CLI
- **model:** gpt-5.5
- **reasoning effort:** low
- **tasks:** clawmeter-openai-path-recovery
- **repository:** /home/tnunamak/code/clawmeter
- **base ref:** 9a2abf7ff463ee9b970fbd02ec74621e84aee4b7
- **verification oracle:** go test ./...
- **replicates:** 1 per row
- **sandbox:** workspace-write

## Result Files

- `/home/tnunamak/.local/state/tokensmash/ab-runs/all-tools-20260611T133907Z/results.json`
- `/home/tnunamak/.local/state/tokensmash/ab-runs/all-tools-20260611T133907Z/results.json`
- `/home/tnunamak/.local/state/tokensmash/ab-runs/all-tools-20260611T133907Z/results.json`
- `/home/tnunamak/.local/state/tokensmash/ab-runs/semmap-20260611T143459Z/results.json`
- `/home/tnunamak/.local/state/tokensmash/ab-runs/packers-20260611T142502Z/results.json`
- `/home/tnunamak/.local/state/tokensmash/ab-runs/packers-20260611T142502Z/results.json`

## Limitations

- One task and one replicate per row; use directionally, not as a confidence interval.
- Rows from different result batches have different paired baselines; compare each row to its own baseline.
- This measures Codex CLI behavior only, not Claude/Gemini or non-coding research sessions.
- Tool exposure is not always tool use; inspect session logs before making global defaults from a row.
