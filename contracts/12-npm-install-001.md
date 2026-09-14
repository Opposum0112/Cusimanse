# Goose-native npm experiment contract

## Question
Observe a pinned npm installation in an isolated researcher-selected environment.

## Workload
```bash
node --version
npm --version
mkdir -p /tmp/npm-test
cd /tmp/npm-test && npm init -y
cd /tmp/npm-test && npm install lodash@4.17.21 --ignore-scripts
```

## Safety
Do not install into unrelated projects or execute package lifecycle scripts for this reference experiment. Use an isolated environment when testing untrusted package behavior.

## Evidence and acceptance
Preserve command output, generated package metadata and relevant observations. Distinguish observed facts from analysis. A completed run requires successful execution plus preserved evidence and independent checking of important conclusions. Missing optional instrumentation is reported as `NOT_DEPLOYED`.
