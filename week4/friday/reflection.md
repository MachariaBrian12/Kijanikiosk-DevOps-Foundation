# Week 4 Friday — Reflection

## Question 1: When did two requirements conflict, and what did you learn?

The conflict surfaced when writing pipeline.sh. Requirement 1 says Terraform must output the server IPs, and Requirement 2 says Ansible must configure those servers. These two requirements are stated separately but they share a hard dependency: Ansible cannot run until the IPs exist, and the IPs do not exist until Terraform has finished applying. The naive approach — writing the inventory before running Terraform — produces an empty file that breaks the entire Ansible run silently.

The resolution was to treat the inventory not as a static file to be authored, but as an artifact to be generated. pipeline.sh extracts each IP immediately after terraform apply completes and writes inventory.ini programmatically before ansible-playbook is called. What I learned is that integration failures rarely announce themselves as errors — they show up as stale data. The inventory having the wrong IPs would not throw an exception; Ansible would simply be unable to reach the hosts. The discipline of asking "where does this value come from, and when does it exist?" before writing the script prevented that failure.

## Question 2: Rewrite one sentence for Tendo. What is lost and what is gained?

Original sentence written for Nia:
"The payments service can read and write only the specific folder it needs. The rest of the server's storage is invisible to it."

Rewritten for Tendo:
"ProtectSystem=strict mounts the root filesystem and /usr read-only for the service process, with ReadWritePaths limited to /opt/kijanikiosk, preventing any write outside that subtree."

What is lost: A non-engineer reading the Tendo version has no mental model to attach it to. The words are precise but opaque — "mounts", "read-only", "subtree" require prior knowledge to interpret.

What is gained: The Tendo version is actionable. An engineer can go directly from that sentence to the systemd unit file and verify it. The Nia version tells you what the control achieves; the Tendo version tells you exactly how to implement and audit it. Precision and verifiability are gained. Accessibility is lost.

## Question 3: What is the most fragile handoff in the pipeline?

The most fragile handoff is the 30-second sleep between terraform apply completing and ansible-playbook starting. This is the point where the pipeline assumes the servers are ready to accept SSH connections. That assumption is not guaranteed.

EC2 instances reach a "running" state in AWS before the operating system has finished booting, before the SSH daemon is listening, and before cloud-init has completed its initialisation sequence. In the test environment, 30 seconds was sufficient. In a production environment with a different base image, a slower instance type, or heavy cloud-init scripts, 30 seconds may not be enough — and the Ansible run will report every host as unreachable.

To make this handoff robust, I would need to know: what base image is being used and how long its cloud-init sequence takes, whether the target environment allows outbound SSH probing so I can replace the sleep with an active readiness check, and whether the instance type has consistent boot times. The correct fix is to replace the fixed sleep with a loop that actively tests SSH connectivity on each host and proceeds only when all three respond — turning a timing assumption into a verified condition.
