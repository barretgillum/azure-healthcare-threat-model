# Security Review Risk Register

This document tracks identified security findings, supporting evidence, risk, recommended remediation, ownership, and validation status for the Azure Healthcare Threat Modeling Lab.

## Review Workflow

Finding → Evidence → Risk → Recommendation → Owner → Due Date → Validation → Closure / Risk Acceptance

---

## SEC-001 — Excessive East-West Network Access

**Finding:**  
Azure VNets allow broad intra-VNet communication by default through the `AllowVnetInBound` NSG rule.

**Evidence:**  
The default NSG rule at priority 65000 allows VirtualNetwork-to-VirtualNetwork inbound traffic.

**Risk:**  
A compromised workload in one application tier could attempt lateral movement into more sensitive tiers.

**Recommendation:**  
Implement explicit higher-priority allow rules for required application flows and deny other VNet traffic before Azure default rules are evaluated.

**Implemented Controls:**
- Internet → Web: TCP 443 allowed
- Web → API: TCP 443 allowed
- API → Data: TCP 1433 allowed
- Other VNet traffic between tiers denied

**Owner:** Cloud / Network Engineering

**Status:** Remediated

**Validation:**  
Verified custom NSG rules take precedence over Azure default `AllowVnetInBound` rules.

---

## SEC-002 — Broad Key Vault Network Exposure

**Finding:**  
Azure Key Vault can be reachable from public networks unless network restrictions are configured.

**Evidence:**  
Initial Key Vault configuration allowed access from all networks.

**Risk:**  
Broad network reachability increases the attack surface for a service containing application secrets.

**Recommendation:**  
Restrict Key Vault network access to approved application subnets and administrative source IPs. Evaluate Private Endpoint deployment for stronger isolation.

**Implemented Controls:**
- Key Vault firewall enabled
- `snet-api` allowed using the Microsoft.KeyVault service endpoint
- Administrative access restricted to an approved client IP for management

**Owner:** Cloud Security

**Status:** Partially Remediated

**Future Improvement:**  
Replace service-endpoint access with Azure Private Endpoint and Private DNS.

---

## SEC-003 — Hard-Coded Application Credentials

**Finding:**  
Applications may rely on credentials embedded in source code, configuration files, or deployment variables.

**Risk:**  
Credentials can be exposed through source repositories, logs, configuration leaks, or developer workstations.

**Recommendation:**  
Store sensitive application secrets in Azure Key Vault and authenticate workloads using managed identities.

**Implemented Controls:**
- Azure Key Vault deployed
- User-assigned managed identity `id-api-healthcare` created
- API identity assigned `Key Vault Secrets User`
- Database connection secret stored in Key Vault

**Owner:** Application Engineering

**Status:** Remediated

**Validation:**  
API workload identity has read-only secret access while administrative secret-management permissions remain separate.

---

## SEC-004 — Excessive Secret Management Permissions

**Finding:**  
Application identities with secret-management permissions could modify or delete secrets in addition to reading them.

**Risk:**  
A compromised application workload could manipulate credentials, disrupt dependent systems, or expand the impact of compromise.

**Recommendation:**  
Separate secret consumption from secret administration using least-privilege RBAC.

**Implemented Controls:**
- `id-api-healthcare` → `Key Vault Secrets User`
- Administrator account → `Key Vault Secrets Officer`

**Owner:** Identity / Cloud Security

**Status:** Remediated

**Validation:**  
Application identity receives read access without secret-management permissions.

---

## SEC-005 — Privileged Access Persistence

**Finding:**  
Permanent assignment of highly privileged roles increases the impact of credential compromise.

**Risk:**  
Compromise of a permanently privileged account could provide immediate administrative access to sensitive cloud resources.

**Recommendation:**  
Use Microsoft Entra Privileged Identity Management (PIM) for eligible, time-limited privileged-role activation with MFA, justification, approval, and auditing where appropriate.

**Owner:** Identity Security

**Status:** Planned

**Future Improvement:**  
Implement and document PIM-based administrative access.

---

## SEC-006 — Incomplete Security Telemetry

**Finding:**  
Security-relevant events may not be centrally collected or correlated.

**Risk:**  
Suspicious authentication, secret access, privileged changes, and network activity may not be detected or investigated quickly.

**Recommendation:**  
Enable diagnostic logging and centralize telemetry in Azure Log Analytics. Add alerting for high-risk events.

**Owner:** Security Engineering

**Status:** Planned

**Future Improvement:**
- Key Vault diagnostic logs
- NSG flow logs where supported
- Entra audit logs
- Azure Activity Logs
- KQL detection queries
