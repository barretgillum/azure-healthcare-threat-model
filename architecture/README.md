# Architecture

This folder contains architecture and data-flow documentation for the Azure Healthcare Threat Modeling Lab.

The environment is designed as a segmented three-tier Azure architecture:

- Web Tier: `snet-web` — `10.10.1.0/24`
- API Tier: `snet-api` — `10.10.2.0/24`
- Data Tier: `snet-data` — `10.10.3.0/24`

The API tier also uses a user-assigned managed identity to access Azure Key Vault using least-privilege RBAC.

## Intended Data Flows

1. External User → Web Tier over HTTPS 443
2. Web Tier → API Tier over HTTPS 443
3. API Tier → Data Tier over TCP 1433
4. API Tier → Azure Key Vault using managed identity
5. Administrator → Azure Key Vault through Azure management interfaces

## Network Segmentation

Network Security Groups are used to restrict communication between tiers.

- Internet → Web: HTTPS 443 allowed
- Web → API: HTTPS 443 allowed
- API → Data: TCP 1433 allowed
- Other VNet traffic between tiers is denied by higher-priority custom NSG rules

This design supports defense in depth and reduces the ability of a compromise in one tier to move laterally into more sensitive application components.
