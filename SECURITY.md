# Security Policy

## Supported version

Security and correctness fixes target the latest release and the default branch.

## Reporting a vulnerability

Do not open a public issue for vulnerabilities that could expose local files,
execute unintended code, or disclose research data. Use GitHub's private
security advisory feature after the repository is published, or contact the
maintainer privately.

Use the repository's private security advisory feature for confidential reports.
Reports should include the affected version, minimal reproduction, impact, and
any proposed mitigation. Do not include confidential research data in public
issues.

## Data-safety boundary

`meta3level` reads local user-selected files and can write audit scripts, RDS
snapshots, tables, and plots only when requested. Users remain responsible for
reviewing output paths and removing identifiable data before sharing artifacts.
