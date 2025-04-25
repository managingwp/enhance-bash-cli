# enhance-bash-cli
A simple bash script to interface with the enhance API at https://apidocs.enhance.com/

Enhance documentation https://enhance.com/docs/

# Installation
1. Clone the repository
```git clone https://github.com/managingwp/enhance-bash-cli.git```
2. Create $HOME/.enhance
'''
API_TOKEN=<enhanced_token
API_URL=https://api.example.com
ORG_ID=<your_org_id>
'''

# Notes 
## Enhance API Documentation
https://apidocs.enhance.com/
## Accessing the Enhance API
```
curl -s -X GET https://[Enhance Controller URL]/api/servers -H "Accept: application/json" -H "Authorization: Bearer [Token]" | jq
```