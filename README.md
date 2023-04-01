[![Build Status](https://travis-ci.org/ITV/domed-city.svg?branch=master)](https://travis-ci.org/ITV/domed-city)

# domed-city
Simple CLI application that wraps the Terraform API.

## Purpose

To consolidate, improve and enforce standards around ITV's use of Terraform across product teams.

This gem provides two main functions:

1. Wrap the main Terraform functions (e.g. `plan`, `apply`).
2. Ensure alignment to ITV's Common Platform VPC and environment policy.

## Disclaimer

This gem is very specific to how ITV utilise Terraform so it is unlikely to be useful to others except
to serve as an example of how we do things.

## Naming

From [Wikipedia](https://en.wikipedia.org/wiki/Domed_city):

> ...the dome is airtight and pressurized, creating a habitat that can be controlled for air temperature, composition and quality, typically due to an external atmosphere (or lack thereof) that is inimical to habitation for one or more reasons.

## Installation

Add to your Gemfile:

```
gem 'domed-city'
```

## Usage

For ease of use, type `bundle exec dome` (you may get some warnings if you do not use `bundle exec`) in the CLI:

```
$ bundle exec dome

  Dome wraps the Terraform API and performs useful stuff.

  Usage:
        dome [--sudo] --<command>
  where <command>s are:
  -p, --plan             Creates a Terraform plan
  -a, --apply            Applies a Terraform plan
  -i, --init             Run Terraform init
  -s, --state            Synchronises the Terraform state
  -o, --output           Print all Terraform output variables
  -t, --statecmd=<s+>    Wrapper arround terraform state
  -r, --refresh          Refresh the state
  -c, --console          Spawn terraform console
  -u, --sudo             Assume itv-root instead of the role specified in profile
  -j, --json             Pass the `-json` arg to plan and apply commands
  -v, --version          Print version and exit
  -h, --help             Show this message
  -e, --environment      Spawn sub-shell with the exported variables
```

Domed is designed to work with a certain directory structure. Your account,product,ecosystem and environment are assigned based on your current directory. The expected directory structure is terraform/$PRODUCT-$ECOSYSTEM/$ENVIRONMENT

It also requires certain things in itv.yaml.

1. Your project (or better product) is defined using the project key in your itv.yaml.
```
project: foo

```
2. Valid environments are defined using the hashmap of ecosystems to environments key in your itv.yaml.
eg
```
ecosystems:
  dev:
    - infradev
    - qa
    - stg
  prd:
    - infraprd
    - prd

```
3. Valid accounts are of the format <project>-dev and <project>-prd and are calculated automatically using your project variable. This is consistent with the .aws/config because dome will try and assume the role based on that account.

### Sudo mode

By default dome will assume the role defined in your AWS profile. If `--sudo` is specified, the value is overwritten by `itv-root` role in the same account.

Use this mode only when you need to manage resources requiring `itv-root`.

### Pin provider versions

Create a file called `.terraform-providers.yaml` in the root of the project:

```
aws: 2.6.0
external: 1.1.0
local: 1.2.0
template: 2.1.0
terraform: 1.0.0
vault: 1.6.0
```

## Development & Releases

In order to make changes, you can point the reference to domed-city in the Gemfile to your local working directory eg
```
gem 'domed-city', :path => '/home/foo/github-repos/domed-city'
```

* Every commit will trigger [travis CI](https://travis-ci.org/ITV/domed-city)
* Make sure you run rake spec & rake rubocop
* To release a new version make a PR with your code changes, update the CHANGELOG and lib/dome/version.rb with your version(semver). Then ask for someone to review your PR and merge it. Then manually create a github release.

## TODO

* Rename project references to product
* Check the usage of certificate section
* Remove dynamoDB state locking (Terraform does that now)
* When everyone moves to 1.1 uncomment and use the TF_VARs cidr_ecosystem_dev/prd
