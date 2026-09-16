# Lab: npm-install-day0

Question: what does a pinned `npm install` do on disposable compute?

## Install (once, from the repo root)

```bash
git checkout harness-neutral-runtime
npm install
```

## Run this lab

```bash
npm run lab:npm-install
```

Then in another terminal:

```bash
curl -s http://127.0.0.1:8787/v1/research/npm-install-day0/state
```

Propose `network.observe`, `workload.npm.install`, `evidence.collect`, or `vm.create` using POST `/v1/research/npm-install-day0/proposals`. Full curl examples are in the repository README.

The starter host uses stub adapters (contract checks only, no real VM).

## Files here

| File | Required | Purpose |
|---|---|---|
| `contract.yaml` | yes | Frozen experiment law |
| `policy.yaml` | yes | allow / deny per capability |
| `fixtures/package.json` | yes | Subject under test |

Do not add `run.sh`, API keys, or extra operator tools.
