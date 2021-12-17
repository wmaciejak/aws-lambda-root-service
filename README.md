# AWS Lambda Root Service

The primary goal of the root service is to glue multiple microservices repositories together. The top part is APIGateway connecting:
- [aws-lambda-boilerplate](https://github.com/wmaciejak/aws-lambda-boilerplate)
- more?

## Setup

If you're running the setup process locally, then check out all modules at the same filesystem level as the [aws-lambda-root-service](https://github.com/wmaciejak/aws-lambda-root-service) repository. So your working directory should look like:
```
src/
  +- aws-lambda-root-service/
  +- aws-lambda-boilerplate/
  +- ...
```

Then execute following script to create symlinks to those repositories inside terraform/modules dir. If you have different dirs stucture, you can adjust symlinks manually.

```bash
bin/link_services_repositories
```

## Potential problems and way to solve them

1. There is a known issue with lack of tracking changes in scope of CORS configuration. It means that when we will create STACK without configured CORS for some endpoint we will not be able to provide CORS configuration during this lifecycle of this stack. The only way to manage it currently is to drop stack and create new one
