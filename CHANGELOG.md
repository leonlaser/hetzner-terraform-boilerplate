# Changelog

## [1.0.2](https://github.com/leonlaser/hetzner-terraform-boilerplate/compare/v1.0.1...v1.0.2) (2026-03-18)


### Bug Fixes

* **ci:** failing retagging of docker images on release ([09f019b](https://github.com/leonlaser/hetzner-terraform-boilerplate/commit/09f019bfc2ae968d497fc4d3aca773ceb6f47c94))

## [1.0.1](https://github.com/leonlaser/hetzner-terraform-boilerplate/compare/v1.0.0...v1.0.1) (2026-03-18)


### Bug Fixes

* **ci:** failing retagging of docker images on release ([#8](https://github.com/leonlaser/hetzner-terraform-boilerplate/issues/8)) ([d208798](https://github.com/leonlaser/hetzner-terraform-boilerplate/commit/d20879899710fca4e39e2f248a4e384c468f2f70))

## 1.0.0 (2026-03-18)


### Features

* **backend:** add dummy database data to test backup and restore ([217d402](https://github.com/leonlaser/hetzner-terraform-boilerplate/commit/217d4020eaf8104c2ad2ed5c601406cb302e31ef))
* **backup:** rework backup for more stability and a better operator experience ([5eb2d26](https://github.com/leonlaser/hetzner-terraform-boilerplate/commit/5eb2d264c36de3264cbb3ccfd44f9bfc03ccb33b))
* **backup:** simplify database restore procedure and allow pausing backups during restore ([1f52b3e](https://github.com/leonlaser/hetzner-terraform-boilerplate/commit/1f52b3eddb6bf381ad11a55b69d306509a23accf))
* **ci:** add Docker changes detection and image retagging on release ([36eb36c](https://github.com/leonlaser/hetzner-terraform-boilerplate/commit/36eb36c28f981cb05f1799101e5d788ff081e9e5))
* **ci:** switch server IP and SSH Port from GitHub vars to secrets ([9558817](https://github.com/leonlaser/hetzner-terraform-boilerplate/commit/9558817649f97b40762d33c1f4478cd999fc1001))
* **docker, terraform:** show database connection example, refine names of example env vars ([73d097e](https://github.com/leonlaser/hetzner-terraform-boilerplate/commit/73d097e66fd6a0e692ea447db20c8c5350c00c75))
* **packer, terraform:** introduce packer and a generic server module ([#3](https://github.com/leonlaser/hetzner-terraform-boilerplate/issues/3)) ([f8c48ed](https://github.com/leonlaser/hetzner-terraform-boilerplate/commit/f8c48ed888367af36314666d4bcebf61c75f9de5))
* **terraform,ansible:** add restore script, simple disk space monitoring and docker cleanup ([#7](https://github.com/leonlaser/hetzner-terraform-boilerplate/issues/7)) ([eabaa3d](https://github.com/leonlaser/hetzner-terraform-boilerplate/commit/eabaa3dd4a3d472f93a567934fa8a85a4016d457))


### Bug Fixes

* **backup:** errors do not lead to error mails being sent ([2ebf810](https://github.com/leonlaser/hetzner-terraform-boilerplate/commit/2ebf810d296f0db2781fc6548b37005308b9f17b))
* **docker:** docker compose project name ignored, NODE_ENV is missing ([97c8a4f](https://github.com/leonlaser/hetzner-terraform-boilerplate/commit/97c8a4f94de3e9d7ccb601c8922b29090c68f11a))
* **packer,terraform:** privilege escalation through backup-related sc… ([#6](https://github.com/leonlaser/hetzner-terraform-boilerplate/issues/6)) ([f971e09](https://github.com/leonlaser/hetzner-terraform-boilerplate/commit/f971e09b6576ab1f656f41572d6beef43def86c8))
* **packer,terraform:** privilege escalation through backup-related scripts owned by ops ([f971e09](https://github.com/leonlaser/hetzner-terraform-boilerplate/commit/f971e09b6576ab1f656f41572d6beef43def86c8))
* **terraform:** database password was created with "random_string" instead of "random_password" ([3c3a92e](https://github.com/leonlaser/hetzner-terraform-boilerplate/commit/3c3a92e4ea6196cd97aeab21034e671650eeb1a8))
* **terraform:** database server is not setup correctly ([68b1565](https://github.com/leonlaser/hetzner-terraform-boilerplate/commit/68b15652d86a52912650c5504b746a50273623a0))
