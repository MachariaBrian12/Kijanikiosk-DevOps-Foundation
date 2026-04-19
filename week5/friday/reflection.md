# Week 5 Friday — Reflection

## Question 1: When did two requirements come into tension?

The tension surfaced between Requirement 1 and Challenge A. Requirement 1 says the pipeline must use a Docker agent, and the Publish stage must authenticate to Nexus. Challenge A explains that inside a Docker container, localhost does not refer to the host VM — it refers to the container itself. These two requirements are not in conflict on paper, but in practice they create a connectivity problem that is invisible until the Publish stage runs and fails with a connection refused error.

The decision I prioritised was correctness over simplicity. The simple fix — using localhost — works when the agent is running directly on the VM but silently breaks the moment Docker is involved. Using the Docker bridge address 172.17.0.1 with --network=host in the agent args ensures the container can reach the host's Nexus instance regardless of how the container is scheduled. I prioritised this because the Publish stage is the only stage that produces a result the deployment pipeline depends on. A publish that appears to succeed but connects to nothing is worse than one that fails loudly.

## Question 2: Rewrite one sentence for Tendo.

Original sentence written for Nia:
"Every time a developer on the KijaniKiosk team saves their work to the shared codebase, an automated process runs within seconds."

Rewritten for Tendo:
"A webhook from the repository triggers a declarative Jenkins pipeline on every push to the feature branch, with SCM polling as a fallback for missed webhook deliveries."

What is the same: both versions describe the same trigger — a code push causes a pipeline to start automatically.

What is different: the Nia version establishes the why and the human action that starts the process. The Tendo version gives the mechanism — webhook, declarative pipeline, fallback polling — which is what an engineer needs to configure, debug, or replicate the system. The Nia version would confuse Tendo if he needed to set up the trigger. The Tendo version would confuse Nia because it requires knowing what a webhook is.

## Question 3: What breaks first at forty developers?

The single part that breaks first is disableConcurrentBuilds(). With four developers, the chance of two pushes overlapping is low. With forty developers pushing to the same branch throughout the day, builds will queue and cancel constantly. A developer who pushes at 10:02 while a build from 10:01 is still running will have their build cancelled. They push again. The same thing happens. The pipeline becomes a bottleneck rather than a quality gate.

What would need to change is the branching strategy. At forty developers, the team needs a model where each developer works on a short-lived feature branch and the pipeline runs per branch rather than per push to a shared main branch. This means the Jenkins job needs to be a multibranch pipeline that creates a separate pipeline instance per branch, each with its own build history and concurrency controls. The shared main branch pipeline then only runs on merges, which are infrequent and deliberate. That change — from a single-branch pipeline to a multibranch pipeline — is what makes the system scale from four to forty without the concurrency lock becoming a daily frustration.
