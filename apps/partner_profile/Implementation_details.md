# Implementation Details

## Based on questions from Lenkov

These are the questions we need to answer. Should reformt them into this document as statements

* Does the PartnerProfile service understands the data it stores, for example:
  * The list of available namespaces
  * The schema for each namespace.
  * Some specific keys in each namespace
  * The values of some keys.
* Does it modify the config on GET /, and if yes for what purpose.
* how we do versioning of the software and the config files
* how we trigger deploy for the software and the config file (specific version on specific Env)
* how the CI/CD shares gets the secret to call the API to update the config (the super-user)
* How the lambda authorizer authenticate normal users via the Partner profile (what API and DB access pattern it uses).
* How/Where we do validation of the partner profile configs. What is the workflow for updating the validation schema (where it resides).
* How do we persist the config in Dynamo
* How we handle secrets inside the config
* How we will handle (in the future) customer-editable settings and inject them in the config
* What access patterns to the config data our API supports ( namespace vs path )
* How we use the data from PartnerProfile to call the webhook (getting the actual OAuth 2 credentials).
* For the verifyIQ — how we handle the requests with embedded files when the API GW has 10MB limit.
* How the partnerProfile notifies all services that a profile has been updated (payload size limits).
