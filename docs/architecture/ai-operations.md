# AI-assisted operations and approval flow

```mermaid
sequenceDiagram
    actor User
    participant Web as Pi Web UI<br/>Tailscale-only
    participant Pi as Pi agent
    participant Context as AGENTS + inventory<br/>runbooks + repository
    participant Gate as Approval rules
    participant Host as Homeserver / Docker
    participant VPS as VPS gateway

    User->>Web: Describe symptom or requested change
    Web->>Pi: Authenticated conversation
    Pi->>Context: Load durable workflow and source of truth
    Pi->>Host: Run redacted status/drift diagnostics
    Host-->>Pi: Health, logs, config hashes, boundaries
    Pi-->>User: Diagnosis and scoped plan

    alt Shell, write, sensitive read, or disruptive action
        Pi->>Gate: Request tool approval
        Gate-->>User: Show proposed operation
        User-->>Gate: Approve or deny
    end

    Pi->>Context: Edit repository source + documentation
    Pi->>Context: Validate Compose/templates and secret exclusions
    Pi->>Host: Deploy one reviewed stack/component
    opt Public edge change
        Pi->>VPS: Validate, back up, install and reload
    end
    Pi->>Host: Verify health, integration and denied access paths
    Pi-->>User: Root cause, change and concrete verification
```

## Control layers

```mermaid
flowchart LR
    phone[Phone on Tailscale]
    token[Pi Web UI token]
    approvals[Approval rules<br/>shell / writes / sensitive reads]
    instructions[Durable agent contract<br/>AGENTS.md + private host context]
    repo[Git working tree<br/>source of truth]
    scripts[Status / drift / deploy scripts]
    host[Host user permissions]
    docker[Docker socket<br/>root-equivalent]

    phone --> token --> approvals --> instructions --> repo --> scripts --> host --> docker

    warning[Approvals and instructions reduce mistakes;<br/>they are not an OS security boundary]
    approvals -.-> warning
    host -.-> warning

    classDef guard fill:#dbeafe,stroke:#2563eb,color:#111827
    classDef power fill:#fee2e2,stroke:#dc2626,color:#111827
    class phone,token,approvals,instructions,repo,scripts guard
    class host,docker,warning power
```

## Durable context for new sessions

New Pi sessions do not depend on conversation memory. They receive:

- Host-level private context from the Pi agent directory
- Repository `AGENTS.md`
- Machine-readable service inventory
- Operations/security runbooks
- Live redacted state from `scripts/status.sh`
- Exact Compose image/config/ownership drift from `scripts/check-drift.sh`

The model still cannot infer undocumented application UI changes. Architecture-
significant settings must be recorded without exporting secret-bearing runtime data.
