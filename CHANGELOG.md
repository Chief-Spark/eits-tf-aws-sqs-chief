# RELEASE NOTES

## 1.6.1 - 14th September 2026

- Updated confluence document links

## 1.6.0 - 5th February 2026

- Added `enable_all_alarm_actions` variable
- Changed default behaviour for alarm actions. Only `ALARM` will always be enabled when `alarm_sns_topics` is specified
- Added `eitsce:parentmodule` tag to child resources

## v1.5.2 - 5th January 2026

- Added optional `prefix` variable to override the default `eits_ce_common` prefix used for queue naming.

## v1.5.1 - 14th August 2025

- Fixed bug when multiple `Statements` are provided in policy_json variable
- Updated pre-commit to 1.3.1

## v1.5.0 - 17th April 2025

- Changed `vars` to `ce_common`
- Updated pre-commit config to 1.3.0
- Updated Cloudwatch Alarms module to 1.3.0
- Updated required Terraform version to 1.5.0

## v1.4.0 - 14th February 2025

- Added policy to enforce the use of secure transport for sending messages to the SQS queue.

## v1.3.0 - 31st January 2025

- Added `cloudwatch_tags` variable to allow adding Cloudwatch specific tagging.
- Bumped `eits-tf-aws-cloudwatch-alarm` module version to `1.2.0`.
- Added `pre-commit`.

## v1.2.1 - 27th Jan 2025

- Updated review date
- Updated aws provider version please refer to https://github.com/hashicorp/terraform-provider-aws/blob/main/CHANGELOG.md for the list of bug fixes and enhancements.
- add `.pre-commit-config` to module

## v1.2.0 - 19th June 2024

- Change default value of `receive_wait_time_seconds` to `null`.
- If `receive_wait_time_seconds` is left at the default `null`, then it will automatically be set to `0` for resources with an "Environment" tag of value "prd", and set to `20` for other environments. This is a cost-saving measure. To override this, set a specific numerical value to `receive_wait_time_seconds`.
- Updated Cloudwatch Alarms module to version 1.1.2.

## v1.1.0 - 19th December 2023

- Added default alarms - ***Please be aware that adding the default alarms may increase the cost of the queue between $0.10 and $0.40 per month. To disable the creation of these alarms, please set the variable `disable_default_alarms` to true***

## v1.0.0 - 3rd November 2023

- Initial release
