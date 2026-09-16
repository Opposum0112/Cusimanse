# Lima provisioning

Lima is optional. The lab will not start a VM until the **host** injects a `LimaProvider` and passes `validateLimaProvider`.

Before a real experiment:

```ts
import { validateLimaProvider, LimaLifecycle } from "@cusimanse/agent-runtime";

await validateLimaProvider(provider, { name: "car-lima-probe", cpus: 1, memory: "1GiB" });
const lima = new LimaLifecycle(provider);
```

That call **creates then destroys** the probe VM. If either step fails, do not open the lab port.

Rules the runtime already applies:

- VM name: lowercase `a-z`, digits, dashes, 2–33 characters
- CPUs: 1–8
- Memory: `4GiB` or `2048MiB` form only
- Mounts: absolute paths, no `..`
- Operator still only proposes `vm.create` / `vm.destroy`. It never receives `limactl`.

The starter `npm run lab:npm-install` host does **not** call Lima. Wire your `limactl` provider in the host process, validate it, then register adapters for `vm.create` and `vm.destroy`.
