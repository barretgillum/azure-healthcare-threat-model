from pathlib import Path
import re

TERRAFORM_FILE = Path(__file__).parent.parent / "terraform" / "main.tf"


def print_finding(identifier, severity, title, evidence, risk, recommendation):
    print("=" * 72)
    print(f"{identifier} | {severity} | {title}")
    print("-" * 72)
    print(f"Evidence:       {evidence}")
    print(f"Risk:           {risk}")
    print(f"Recommendation: {recommendation}")
    print()


def main():
    if not TERRAFORM_FILE.exists():
        print(f"ERROR: Terraform file not found: {TERRAFORM_FILE}")
        return

    terraform = TERRAFORM_FILE.read_text(encoding="utf-8")

    findings = 0

    print("\nAzure Healthcare Threat Modeling Lab")
    print("Automated Terraform Security Review\n")

    # ------------------------------------------------------------------
    # Check 1: Broad inbound allow rules
    # ------------------------------------------------------------------
    nsg_rule_blocks = re.findall(
        r'resource\s+"azurerm_network_security_rule"\s+"[^"]+"\s*\{(.*?)\n\}',
        terraform,
        re.DOTALL,
    )

    broad_rule_found = False

    for block in nsg_rule_blocks:
        is_inbound = re.search(
            r'direction\s*=\s*"Inbound"',
            block,
            re.IGNORECASE,
        )

        is_allow = re.search(
            r'access\s*=\s*"Allow"',
            block,
            re.IGNORECASE,
        )

        source_any = re.search(
            r'source_address_prefix\s*=\s*"\*"',
            block,
            re.IGNORECASE,
        )

        destination_any = re.search(
            r'destination_port_range\s*=\s*"\*"',
            block,
            re.IGNORECASE,
        )

        if is_inbound and is_allow and source_any and destination_any:
            broad_rule_found = True
            break

    if broad_rule_found:
        findings += 1
        print_finding(
            "AUTO-001",
            "HIGH",
            "Broad inbound NSG rule detected",
            'An inbound NSG rule allows source "*" to destination port "*".',
            "An internet-accessible broad allow rule could expose unintended "
            "services and increase attack surface.",
            "Restrict inbound access to required source ranges, protocols, "
            "and destination ports only.",
        )
    else:
        print("[PASS] No unrestricted inbound allow rule to all ports detected.")

    # ------------------------------------------------------------------
    # Check 2: Key Vault public endpoint
    # ------------------------------------------------------------------
    if re.search(
        r'public_network_access_enabled\s*=\s*true',
        terraform,
        re.IGNORECASE,
    ):
        findings += 1
        print_finding(
            "AUTO-002",
            "MEDIUM",
            "Key Vault public network endpoint enabled",
            "public_network_access_enabled = true",
            "The Key Vault still exposes a public service endpoint. Network "
            "ACLs can restrict access, but a private endpoint would provide "
            "stronger network isolation.",
            "Evaluate Azure Private Endpoint and Private DNS for production "
            "deployments. Maintain default-deny network ACLs in the meantime.",
        )
    else:
        print("[PASS] Key Vault public network access is disabled.")

    # ------------------------------------------------------------------
    # Check 3: Default-deny Key Vault firewall
    # ------------------------------------------------------------------
    if re.search(
        r'network_acls\s*\{.*?default_action\s*=\s*"Deny"',
        terraform,
        re.DOTALL | re.IGNORECASE,
    ):
        print("[PASS] Key Vault network ACL uses default deny.")
    else:
        findings += 1
        print_finding(
            "AUTO-003",
            "HIGH",
            "Key Vault default-deny firewall not detected",
            'Expected network_acls with default_action = "Deny".',
            "Without default-deny network controls, unauthorized network "
            "locations could have a path to the Key Vault endpoint.",
            "Configure Key Vault network ACLs with default_action set to Deny.",
        )

    # ------------------------------------------------------------------
    # Check 4: Managed identity
    # ------------------------------------------------------------------
    if 'resource "azurerm_user_assigned_identity"' in terraform:
        print("[PASS] User-assigned managed identity detected.")
    else:
        findings += 1
        print_finding(
            "AUTO-004",
            "HIGH",
            "Managed identity not detected",
            "No azurerm_user_assigned_identity resource was found.",
            "Applications may fall back to stored credentials or service "
            "principal secrets.",
            "Use an Azure managed identity for workload authentication.",
        )

    # ------------------------------------------------------------------
    # Check 5: Least-privilege Key Vault role
    # ------------------------------------------------------------------
    if 'role_definition_name = "Key Vault Secrets User"' in terraform:
        print("[PASS] Key Vault Secrets User RBAC assignment detected.")
    else:
        findings += 1
        print_finding(
            "AUTO-005",
            "MEDIUM",
            "Expected least-privilege Key Vault role not detected",
            'No role assignment for "Key Vault Secrets User" was found.',
            "An application identity could receive unnecessarily broad "
            "permissions to manage secrets or the vault.",
            "Assign the workload only the minimum Key Vault data-plane role "
            "required for its function.",
        )

    # ------------------------------------------------------------------
    # Check 6: Diagnostic logging
    # ------------------------------------------------------------------
    if (
        'resource "azurerm_monitor_diagnostic_setting"' in terraform
        and 'category = "AuditEvent"' in terraform
    ):
        print("[PASS] Key Vault audit diagnostic logging detected.")
    else:
        findings += 1
        print_finding(
            "AUTO-006",
            "MEDIUM",
            "Key Vault audit logging not detected",
            "No diagnostic setting containing AuditEvent was found.",
            "Secret access and administrative activity may be harder to "
            "investigate or attribute.",
            "Send Key Vault AuditEvent logs to a centralized Log Analytics "
            "workspace.",
        )

    # ------------------------------------------------------------------
    # Check 7: Web -> API segmentation
    # ------------------------------------------------------------------
    if (
        '"Allow-Web-To-API-HTTPS"' in terraform
        and 'source_address_prefix       = "10.10.1.0/24"' in terraform
        and 'destination_port_range      = "443"' in terraform
    ):
        print("[PASS] Web-to-API HTTPS segmentation rule detected.")
    else:
        findings += 1
        print_finding(
            "AUTO-007",
            "MEDIUM",
            "Expected Web-to-API segmentation rule not detected",
            "Could not confirm Web subnet to API subnet TCP 443 rule.",
            "Uncontrolled east-west traffic can increase lateral movement "
            "opportunities.",
            "Permit only required Web-to-API application traffic.",
        )

    # ------------------------------------------------------------------
    # Check 8: API -> Data segmentation
    # ------------------------------------------------------------------
    if (
        '"Allow-API-To-Data-SQL"' in terraform
        and 'source_address_prefix       = "10.10.2.0/24"' in terraform
        and 'destination_port_range      = "1433"' in terraform
    ):
        print("[PASS] API-to-Data SQL segmentation rule detected.")
    else:
        findings += 1
        print_finding(
            "AUTO-008",
            "MEDIUM",
            "Expected API-to-Data segmentation rule not detected",
            "Could not confirm API subnet to Data subnet TCP 1433 rule.",
            "Broad access to the data tier can increase the impact of a "
            "compromised application component.",
            "Restrict database connectivity to the approved API tier and "
            "required database port.",
        )

    print("=" * 72)

    if findings == 0:
        print("RESULT: No security findings detected.")
    else:
        print(f"RESULT: {findings} security finding(s) detected.")

    print("=" * 72)


if __name__ == "__main__":
    main()