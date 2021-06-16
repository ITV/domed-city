# 11.0.1
BUGFIX:
  - Use new providercache dir for tf14 onwards

# 11.0.0
BREAKING:
  - Update providers for namespace functionality as part of TF14 update
  - Remove TF lock file when running TF plan
  - This version should only be used when updating to TF14 (chromium release)

# 10.4.1
BUGFIX:
  - Set `AWS_REGION` envvar rather than `AWS_DEFAULT_REGION`
    - this is to fix a [provider bug](https://github.com/hashicorp/terraform-provider-aws/issues/5981) that prevents you from creating S3 buckets outside of `eu-west-1`

# 10.4.0
FEATURE:
  - Show remaining seconds left on session
  - Fix typo

# 10.3.0
FEATURE:
  - Export Main Environment when running actions at Ecosystem level to support the environment to ecosystem migration

# 10.2.0
FEATURE:
  - Check AWS session time before running. If the remaining session time is <20 minutes then clear the session and get a new one. If less than 40 minutes, check if the user wants to clear the session before continuing. This is for the case of long-running applys such as EKS upgrades.

# 10.1.1
FEATURE:
  - Load secrets into env vars for terraform import

# 10.1.0
FEATURE:
  - Add terraform import option

# 10.0.0
BREAKING:
  - Update the providers download to support the new local provider path. Also provides a second compatibility provider dir for when migrating from tf1
2 -> tf13. This version should only be used when updating to TF13 (scandium release)

# 9.2.1
BUGFIX:
- Only warn on missing hiera lookups

# 9.2.0
FEATURE:
- Add `ecoroles` level at the ecosystem

# 9.1.1
BUGFIX:
- Handle outputs of `aws-vault` on Linux clients

# 9.1.0
FEATURE:
- Check terraform version against .terraform-version before running

# 9.0.0
BREAKING:

- Upgrade aws-sdk to v3
- This requires the following updates in your infra's Gemfile:
  - Update: gem 'aws-sdk-core', '~> 3'
  - Update lugus gem to at least 'v9.0.0'
  - Remove: gem 'aws_assume_role', '1.2.1'

BUGFIX:
- Fix zip file open for use in containers

# 8.0.0

BREAKING CHANGES:
- Remove `aws_assume_role` gem
- Use `aws-vault` for assuming role
  - Install it separately: https://github.com/99designs/aws-vault
  - New AWS config format: Uses `<product>-<ecosysyem>-[dev|pe|root]` profile names
  - If you want to use `itv-dev` role by default put `export ITV_DEV=true` into your shell's rc file
  - To skip invoking `aws-vault` run `export FREEZE_AWS_ENVVAR=true`
- To use Yubikey for MFA, set the following environment variable (with your email!):
  - `export YUBIKEY_MFA='Amazon Web Services:first.last@itv.com@itv-root'`
  - you must have ykman installed for this to work: https://developers.yubico.com/yubikey-manager/

# 7.1.0
FEATURES:
- Pin to Ruby 2.7.1
- Update vulnerable Rake

# 7.0.3
FEATURES:
- Allow dome to use `params/env.tf` from the environment level when running on new run-level `services`

# 7.0.2
FEATURES:
- Add `service` level where a business service can be defined within `<product>-infra/terraform/<product>-<ecosystem>/<environment>/<services>/<serviceX>`. This ensures a one services AWS S3 bucket with multiple uniquely named terraform state files.
- Add explicit validation for `services` and `roles` levels.

`NOTE: Do not use v7.0.0 or v7.0.1 as v7.0.2 contains the necessary incremental fixes.`

# 7.0.1
FEATURES:
- Provide better naming convention for service-level state file i.e. `<project>-<ecosystem>-<environment>-<services>.tfstate`.

# 7.0.0
FEATURES:
- Add `service` level where a business service can be defined within `<product>-infra/terraform/<product>-<ecosystem>/<environment>/<service>`. This ensures a service-specific AWS S3 bucket and terraform state file.

# 6.18.2

FEATURES:
- Provide clearer error if required profile is missing from aws config

# 6.18.1

BUGFIX:
- Add `rubyzip` dependency

# 6.18.0

FEATURES:
- Add Hiera secrets to `dome --environment`

# 6.17.1

BUGFIX:
- Fix provider permissions
- Fix empty provider config

# 6.17.0

FEATURES:
- Install and configure Terraform providers if `.terraform-providers.yaml` file is present in the root of the project

# 6.16.0

FEATURES:

- Lookup Hiera secrets using a modified config (dome_ro Vault role)

# 6.15.0

FEATURES:
- `--environment` command to export variables and spawn a sub-shell

# 6.14.0

FEATURES:
- Simplify Environment class
  - changes per level
    - ecosystem level
      - environment set explicitly to nil
      - exports TF_VAR_dev_ecosystem_environments
      - exports TF_VAR_prd_ecosystem_environments
    - product level
      - environment set explicitly to nil
      - exports TF_VAR_cidr_ecosystem (prd cidr)
- More consistent prints

# 6.13.0

FEATURES:
- Locate project root and itv.yaml

# 6.12.0

FEATURES:
- Add `--sudo` option to assume `itv-root`

# 6.11.2

REMOVED:
- rvm 2.2.4 to ensure C.I is ran on rvm 2.3.1 only.

# 6.11.1

BUGFIX:
- Pin `dry-validation` gem to '< 0.13.1' to work with Ruby v2.3.1.

# 6.11.0

FEATURE:
- Use secrets-init endpoint for initialization

# 6.10.0

FEATURES:
- Initialize Vault if necessary (requires PE)
- Use VAULT_TOKEN environment variable if set

# 6.9.0

FEATURES:
- Add secrets-init and secrets-config levels
- Better error handling

# 6.8.1

FEATURES:
- Fix account on product level

# 6.8.0

FEATURES:
- Parse product from itv.yaml

# 6.7.0

FEATURES:
- prepend `itv-` to the state bucket names, to help avoid name collision
- add state bootstrap to init command, with small delay to avoid S3 asynchronicity

# 6.6.0

FEATURES:
- add `--init` option to invoke `terraform init`

# 6.5.0

FEATURES:
- allow option to conserve existing environment variables rather than overriding them
  - this is required for cross account role assuming from `ec2`
  - default behaviour is unchanged
- update deprecated gem

# 6.4.0


FEATURES:
 - Added refresh, console and state commands (dome -r,dome -c,dome -t).
 - Added level support. Where level is ecosystem,environment,product,roles. Each level has its own remote state.

# 6.3.2

BUGFIX:

- Give a useful error message if you try to run without Puppet private keys available.

# 6.3.1

BUGFIX:

- Remove cidr_ecosystem_dev/prd because they are breaking existing runs(in infraprd). Will enable again in the future once everyone is using 1.1.

# 6.3.0

FEATURES:

 - Exports TF_VARS based on the current directory
 - Update README
 - Simplify output. Remove default debug mode.
 - Doesn't delete cache folder

# 6.2.0

FEATURES:

- Set TF_VAR_product,ecosystem,envname
- Replace envname with env so we can transition to the new env name
- You can remove product,envname,ecosystem from your params/env.tfvars as they are now discovered from your directory structure
# 6.1.0

FEATURES:
  - added support for aws-assume-role with temporary STS credentials

REQUIRED CHANGES:

  - ruby > `v2.1`
  - added dependency on `aws-assume-role` Gem
  - please follow [setup instructions](https://github.com/ITV/cp-docs/wiki/howto:-AWS-Assume-Role)

# 6.0.0

BREAKING CHANGE:

  - Terraform 0.10.x support

REQUIRED CHANGES:

  - Add a block for the s3 backend in the `main.tf` (example from root-infra):
    ```
    terraform {
      backend "s3" {
        bucket         = "root-tfstate-infraprd"
        key            = "infraprd-terraform.tfstate"
        region         = "eu-west-1"
        dynamodb_table = "root-tfstate-infraprd"
      }
    }
    ```
  - Pin the providers to specific versions: (example from root-infra):
    ```
    provider "aws" {
      region = "${var.region}"
      version = "1.0.0"
    }

    provider "template" {
      version = "1.0.0"
    }

    provider "terraform" {
      version = "1.0.0"
    }
    ```

# 5.0.0

Update hiera to 3.x, required for projects which implement Puppet 5.x

# 4.0.0

Breaking change:

Ecosystem variable within the ITV yaml now needs to be a hash - the Terraform run will fail hard if the ecosystems are not set to a hash within the config

# 3.1.0

Added hiera-eyaml support.

This allows us to use encrypted Terraform variables via hiera lookups (the `hiera.yaml` is consumed).

It also allows us to decrypt and extract SSL certificates or SSH keys which can then be used as appropriate.

In order to utilise these two improvements, you must update your `itv.yaml` e.g.:

```
dome:
  hiera_keys:
    artifactory_password: 'deirdre::artifactory_password'
  certs:
    sit.phoenix.itv.com.pem: 'phoenix::sit_wildcard_cert'
    phoenix.key: 'phoenix::certificate_key'
```

This release also containes:
- Improved debugging/output messages.
- More tests.

# 3.0.1

Forcibly unsetting environment variables `AWS_ACCESS_KEY` and `AWS_SECRET_KEY`.
This is to prevent bypassing the user's local credentials specified in `~/.aws/credentials`.

Fixed bug where `dome --state` needed to be called first when setting up a new environment.
This requires some further testing but we may wish to remove this CLI option in the future.

# 3.0.0

Thanks to [@Russell-IO](https://github.com/Russell-IO) for helping with these changes.

- Internal refactoring.
- More tests added (but lots more needed).
- Improved debug output and explained up front how variables are set.
- Removed `aws_profile_parser` and used environment variables instead to unify
the AWS CLI and terraform calls.

ROADMAP:
- Merge [@mhlias](https://github.com/mhlias) changes that implements assumed-role support.
