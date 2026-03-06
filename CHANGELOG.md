# Changelog

## 1.0.0 (2026-03-06)


### Features

* add CI release workflow ([225a561](https://github.com/leonlaser/hetzner-terraform-boilerplate/commit/225a5618c9b2adecef7cd7adb326466626ee1e46))
* **ci:** add Docker changes detection and image retagging on release ([3a7adbf](https://github.com/leonlaser/hetzner-terraform-boilerplate/commit/3a7adbf31ce6d8cddfcc6d29265aef8be75b2f9b))
* finish docker examples and CI workflows ([f6064e1](https://github.com/leonlaser/hetzner-terraform-boilerplate/commit/f6064e18d2dce4001204a92a8d45cd568860a406))
* harden server access and leaking secrets during provisioning ([62110f8](https://github.com/leonlaser/hetzner-terraform-boilerplate/commit/62110f881440e2169fada6f8c562a7b8612832fb))
* make manual symlinks obsolete and add shared tfvars support ([5f9dbd1](https://github.com/leonlaser/hetzner-terraform-boilerplate/commit/5f9dbd10e1836ca4cfe33be6045bcd2c8732b4ee))
* rerun Terraform provisioners on server replacement ([be6d04d](https://github.com/leonlaser/hetzner-terraform-boilerplate/commit/be6d04d398f5f0dbc5d4e4cf2a9b172f3f15a465))
* update with new learnings from actual project ([914b474](https://github.com/leonlaser/hetzner-terraform-boilerplate/commit/914b4742af371ceb33f9f6f82d27dfe610ea3a7a))


### Bug Fixes

* add missing context during docker build ([e2791f4](https://github.com/leonlaser/hetzner-terraform-boilerplate/commit/e2791f4a27014666a84dfa2b0fc37a541d98c98b))
* **ci:** correct database compose file paths in deployment script ([ebec951](https://github.com/leonlaser/hetzner-terraform-boilerplate/commit/ebec951330ffbef087b69487951a568b85dad051))
* **ci:** switch APP_SERVER_IP and APP_SERVER_SSH_PORT from vars to secrets ([33e76f3](https://github.com/leonlaser/hetzner-terraform-boilerplate/commit/33e76f32cc1c89bf007c1939ffadb8d3f72f1fd2))
* docker services are not attached to proxy network ([35bde04](https://github.com/leonlaser/hetzner-terraform-boilerplate/commit/35bde04ad34ec05ba5bb7a621c34f49fc078030c))
* missing configuration regarding tls/let's encrypt ([6440602](https://github.com/leonlaser/hetzner-terraform-boilerplate/commit/6440602b764e5d486fe3b0ecba3b584d33608910))
* missing port during ssh connection in CI ([196455a](https://github.com/leonlaser/hetzner-terraform-boilerplate/commit/196455aff6acf13ced84ee2143757d923200b768))
* remove specific env vars and allow users to define their own ([778d047](https://github.com/leonlaser/hetzner-terraform-boilerplate/commit/778d04768e5577ba51dbbd20181a88a4af7e89d9))
* **traefik:** fix certificate resolvers not being configured correctly ([635bd76](https://github.com/leonlaser/hetzner-terraform-boilerplate/commit/635bd764d718e70d1d206f4fec43a0fb8c19feef))
* typo in image name during build in CI ([6bde7df](https://github.com/leonlaser/hetzner-terraform-boilerplate/commit/6bde7df52e6201783fb14c545b3aae3d3b2ba2d6))
* typo when creating traefik config folder ([89a556e](https://github.com/leonlaser/hetzner-terraform-boilerplate/commit/89a556e4f51fe351530f9eeb3d5c1a35ec4ed963))
* wrong filenames in during deployment via CI ([5d69980](https://github.com/leonlaser/hetzner-terraform-boilerplate/commit/5d699800ac866ff932f12c8bb61639bc33b84645))
* wrong path to Dockerfiles in CI workflow ([8120c0b](https://github.com/leonlaser/hetzner-terraform-boilerplate/commit/8120c0b6b09eebe15662f9911eb3728b05758ed5))
