# Reflection

## Question 1: When did you discover two requirements were in conflict?

The clearest conflict appeared during Challenge C — logrotate and PrivateTmp.
The logrotate postrotate script needed to signal kk-logs to reopen its log
file handles after rotation. The standard command is systemctl reload, but
reload only works if the unit has an ExecReload= directive. Without it,
systemctl reload exits silently with no error, and the service never reopens
its log handles. The lesson was that two requirements that look independent
(log rotation and service hardening) can interact in ways that are only
visible when you test the composed system, not the individual parts.

## Question 2: Technical vs non-technical language

Nia document sentence:
"Services cannot gain more permissions than they started with."

Tendo version:
"NoNewPrivileges=yes prevents privilege escalation via setuid binaries or
ambient capability inheritance after exec."

What is lost in the Nia version: precision. An engineer reading the Nia
version does not know which mechanism is being used or how to verify it.
What is gained: clarity of purpose. Nia understands the risk being mitigated
without needing to know the implementation. The Nia version answers "why"
while the Tendo version answers "how". Both are necessary — for different audiences.

## Question 3: Most fragile part of the script

The most fragile part is the package version pinning in Phase 1. The script
runs apt-get install without specifying an exact version, then sets a hold.
If the package repository has a newer version than what is currently installed,
apt will upgrade to that version before the hold is set. In a production
environment where the target server has a different package mirror, or where
the mirror was updated between our test and deployment, the installed version
could differ from what was tested.

To make this robust, I would need to know the exact package versions required,
pin them in /etc/apt/preferences.d/ before installing, and verify the installed
version matches the expected version explicitly. This requires knowing the target
environment's package mirror and testing against it before deployment.
