[![Build Status](https://travis-ci.org/ITV/domed-city.svg?branch=master)](https://travis-ci.org/ITV/domed-city)

# domed-city
Simple CLI application that wraps the Terraform API.

## Purpose

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
       dome [command]
where [commands] are:
  -p, --plan            Creates a Terraform plan
  -a, --apply           Applies a Terraform plan
  -s, --state           Synchronises the Terraform state
  -o, --output          Print all Terraform output variables
  -v, --version         Print version and exit
  -h, --help            Show this message
```

### Version >=3.0.0 configuration requirements 
Your environment's `itv.yaml` needs to include the following keys to be able to work with STS tokens:

```
root-profile: profile_name_in_aws_config
accounts-mapping:
  account-name1: account-id
  account-name2: account-id
assumed-role: role_name_to_assume

```


### NOTICE

When used for the first time in an environment you need to run `dome -s` for domed-city to create the S3 bucket and and enable file versioning on it. If you run it after the bucket has been created, it will just sync the remote state, something planning already does by default.

## Acknowledgment
The initial release of `domed-city` is based on the original, and unpublished work, done by @stefancocora and @madAndroid for an internal project at itv.
