# iac-azure-bicep

## Usage

### Deploying Azure resources

Create an input parameter (json file) and execute the following command.

```bash
az deployment sub create -l eastasia -f ./main.bicep --parameters @<input.parameters.json>
```
