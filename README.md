# enhance-bash-cli
A simple bash script to interface with the enhance API at https://apidocs.enhance.com/

Enhance documentation https://enhance.com/docs/

# Installation
1. Clone the repository
```git clone https://github.com/managingwp/enhance-bash-cli.git```
2. Create $HOME/.enhance with at least one named profile section:
```
[default]
API_TOKEN=<enhanced_token>
API_URL=https://api.example.com
ORG_ID=<your_org_id>
CLUSTER_ORG_ID=<your_server_org_id>
```

You can add multiple profiles:
```
[production]
API_TOKEN=<prod_token>
API_URL=https://api.production.example.com
ORG_ID=<prod_org_id>
CLUSTER_ORG_ID=<prod_cluster_org_id>

[staging]
API_TOKEN=<staging_token>
API_URL=https://api.staging.example.com
ORG_ID=<staging_org_id>
CLUSTER_ORG_ID=<staging_cluster_org_id>
```

## Profile Usage
- If only one profile exists, it is used automatically.
- If multiple profiles exist, you will be prompted to select one.
- Use `--profile <name>` (or `-p <name>`) to skip the prompt:
  ```
  ./ebc -c servers --profile production
  ```
- If `API_TOKEN` is already set as an environment variable, the config file is skipped entirely.

# Notes
## Organization ID's Explained
- The organization ID is a unique identifier for your organization within the Enhance platform.
- There is a cluster ORG_ID, which you'll find under "Settings->Access Tokens" https://cp.domain.com/settings/access-tokens
- When you create a customer, they will have their own organization ID.
- 
## Enhance API Documentation
https://apidocs.enhance.com/
## Accessing the Enhance API
```
curl -s -X GET https://[Enhance Controller URL]/api/servers -H "Accept: application/json" -H "Authorization: Bearer [Token]" | jq
```