# host_vars

Per-host variables for remote hosts: `<inventory-hostname>.yml`. Every file here except this README is git-ignored.

Typical contents for a VPS:

```yaml
void_target_user: deploy
user_password_hash: "$6$..."          # openssl passwd -6
user_ssh_keys:
  - "ssh-ed25519 AAAA... me@laptop"
timezone_name: Asia/Tehran
swap_size: 2G
ansible_become_password: "..."         # only when ansible_user isn't root
```

Encrypt the file with `ansible-vault encrypt inventory/host_vars/<host>.yml` and run with `--ask-vault-pass`.
