# enhance-bash-cli
A simple bash script to interface with the enhance API at https://apidocs.enhance.com/

Enhance documentation https://enhance.com/docs/

# Installation
1. Clone the repository
```git clone https://github.com/managingwp/enhance-bash-cli.git```
2. Create $HOME/.enhance
'''
API_TOKEN=<enhanced_token>
API_URL=https://api.example.com
ORG_ID=<your_org_id> # This is the organization for the organization commands
CLUSTER_ORG_ID=<your_server_org_id> # This is the cluster organization ID for cluster commands
'''

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