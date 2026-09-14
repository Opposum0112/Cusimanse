# Goose-native security model

Cusimanse is an agent workflow, not a sandbox. Goose can execute developer tools with the permissions available to its process, so researchers must choose and configure an appropriate isolated environment.

## Native controls

- Goose tool permissions and extension configuration control what the agent can invoke.
- Container Use provides an isolated development environment for experiments that need containment.
- Separate experiment directories and Git branches provide workflow isolation.
- Human review remains required for security-sensitive research decisions.

## Non-native controls

Lima/QEMU policy controllers, custom gateway enforcement, and custom agent firewalls are not dependencies of the Goose-native project. They may be used externally, but are outside this branch's supported execution architecture.

## Evidence rule

Tool output and files produced by the workload are evidence. Model-generated claims are hypotheses/analysis until supported by observable artifacts.
