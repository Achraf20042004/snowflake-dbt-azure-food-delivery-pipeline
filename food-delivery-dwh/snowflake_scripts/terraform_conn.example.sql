-- EXAMPLE ONLY — mock values for GitHub.
-- Copy to terraform_conn.sql (gitignored) and replace with your real RSA public key.
-- Generate a key pair locally; never commit private keys (*.p8).

use role accountadmin;

create user terraform_svc
    type = service
    default_role = sysadmin
    rsa_public_key = 'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAwMockPublicKeyForDemoOnlyReplaceWithYourOwnKeyMaterialXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXwIDAQAB'
    comment = 'Service user for Terraform (example)';

grant role sysadmin to user terraform_svc;
grant role securityadmin to user terraform_svc;

select current_organization_name(), current_account_name();
