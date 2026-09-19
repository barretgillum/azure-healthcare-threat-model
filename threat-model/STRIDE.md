# STRIDE Threat Model

This document applies the STRIDE framework to the primary data flows in the Azure Healthcare Threat Modeling Lab.

## Trust Boundaries

The main trust boundaries are:

1. External User → Web Tier
2. Web Tier → API Tier
3. API Tier → Data Tier
4. API Tier → Azure Key Vault
5. Administrator → Azure Key Vault

---

## 1. External User → Web Tier

| STRIDE Category | Threat | Example Controls |
|---|---|---|
| Spoofing | An attacker impersonates a legitimate user using stolen credentials or a hijacked session. | MFA, strong authentication, secure session handling |
| Tampering | Requests are modified or malicious input is submitted to the application. | TLS, input validation, secure coding practices |
| Repudiation | A user performs an action that cannot later be reliably attributed to them. | Authentication logs, application audit logs, timestamps |
| Information Disclosure | Sensitive information is exposed to an unauthorized user. | HTTPS, authorization checks, data minimization |
| Denial of Service | Excessive requests make the web application unavailable. | Rate limiting, WAF, load balancing, DDoS protections |
| Elevation of Privilege | A normal user gains access to privileged functionality. | RBAC, server-side authorization, least privilege |

---

## 2. Web Tier → API Tier

| STRIDE Category | Threat | Example Controls |
|---|---|---|
| Spoofing | An attacker impersonates the web application or reuses a stolen token to call the API. | Service authentication, token validation, managed identity |
| Tampering | Requests or API responses are modified or manipulated. | TLS, input validation, signed tokens |
| Repudiation | API requests cannot be reliably tied to a user, session, or calling service. | Centralized logging, correlation IDs, authenticated service identity |
| Information Disclosure | The API returns more data than the caller is authorized to receive. | Authorization checks, data minimization, least privilege |
| Denial of Service | Excessive or malicious requests overwhelm the API. | Rate limiting, throttling, health monitoring |
| Elevation of Privilege | A lower-privileged user or compromised web tier accesses privileged API functions. | RBAC, server-side authorization, least privilege |

---

## 3. API Tier → Data Tier

| STRIDE Category | Threat | Example Controls |
|---|---|---|
| Spoofing | Another workload impersonates the API and attempts to connect to the database. | Strong service authentication, restricted source subnet |
| Tampering | Queries or stored data are modified without authorization. | TLS, parameterized queries, restricted write permissions |
| Repudiation | Data changes cannot be attributed to a specific identity or application action. | Database auditing, application logs, correlation IDs |
| Information Disclosure | The API retrieves records beyond what the application requires. | Least-privilege database roles, data minimization, encryption |
| Denial of Service | Excessive database requests exhaust connections or resources. | Connection limits, monitoring, resource controls |
| Elevation of Privilege | A compromised API gains administrative database rights. | Least-privilege database roles, separate service identity |

---

## 4. API Tier → Azure Key Vault

| STRIDE Category | Threat | Example Controls |
|---|---|---|
| Spoofing | Another workload impersonates the API identity to retrieve secrets. | Azure managed identity |
| Tampering | A secret request, returned secret, or stored secret is modified without authorization. | TLS, Key Vault protections, RBAC |
| Repudiation | Secret access cannot be traced to the identity that performed it. | Key Vault logging, Azure activity logs |
| Information Disclosure | The API accesses secrets outside its required scope. | Key Vault Secrets User, firewall restrictions, least privilege |
| Denial of Service | Secret retrieval is disrupted by excessive requests or service unavailability. | Monitoring, retry logic, resiliency planning |
| Elevation of Privilege | The API identity gains secret-management or administrative permissions. | Narrow RBAC assignments, separation of duties |

---

## 5. Administrator → Azure Key Vault

| STRIDE Category | Threat | Example Controls |
|---|---|---|
| Spoofing | An attacker steals administrator credentials or a session and impersonates the administrator. | MFA, Conditional Access |
| Tampering | A privileged identity modifies, disables, replaces, or deletes secrets or vault configuration. | RBAC, change controls, soft delete |
| Repudiation | A privileged change cannot later be attributed to the administrator who performed it. | Audit logging, activity logs |
| Information Disclosure | An administrator can view secrets beyond their operational need. | Least privilege, role separation |
| Denial of Service | A privileged user deletes or disables critical secrets or changes network settings. | Soft delete, purge protection, change controls |
| Elevation of Privilege | An administrator gains broader permissions than intended. | PIM, RBAC, approval workflows |
