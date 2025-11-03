# Secure /etc versioning with git-crypt + etckeeper + GitHub backup

These instructions describe how this server protects `/etc` by keeping a **fully encrypted Git history** of configuration files.

The goals:

- Track configuration changes in `/etc`
- Never commit secrets in clear text
- Allow versioning automation via `etckeeper`
- Push **encrypted** backups to a private GitHub repo
- Store encryption key offline for disaster recovery

This setup ensures **no sensitive data ever leaves the system unencrypted**.

## System requirements

The Makefile automates installation, but for reference:

```
git
git-crypt
etckeeper
```

No GPG keys are required — a **symmetric key** is used instead.

## Repository layout

The repository lives **inside `/etc` itself**:

```
/etc/.git              # local encrypted git repo
/etc/.gitattributes    # lists files to encrypt
/etc/Makefile          # automation commands
/etc/README.md         # this file
```

## First-time setup

Initialize `/etc` as an encrypted Git repository:

```bash
cd /etc
sudo make secure-init
```

This performs:

1. Install required tools (if missing)
2. Initialize clean Git repo
3. Register `.gitattributes` before any commit
4. Initialize `git-crypt`
5. Initialize `etckeeper` without cleartext commit
6. Create first fully-encrypted commit
7. Prompt to export the symmetric key
8. Verify encryption (checks `/etc/shadow`)

## Export the encryption key (IMPORTANT)

You **must** save the encryption key offline:

```bash
sudo git-crypt export-key /root/etc-git-crypt.key
sudo chmod 600 /root/etc-git-crypt.key
```

Store this file **off the server**:

- USB key kept offline
- Password manager
- Printed QR locked in a safe

If you lose this key, you **cannot decrypt the repo**.

## Daily operations

### Check status

```bash
sudo git status
```

### Manual commit (usually not needed)

```bash
sudo git add -A
sudo git commit -m "manual config commit"
```

`etckeeper` normally commits before/after package upgrades.

## Remote backup to GitHub

### First-time remote setup

```bash
sudo make set-remote
```

Example private repo URL:

```
git@github.com:YOURUSER/etc-server.git
```

### Push encrypted backup

```bash
sudo make backup-remote
```

Nothing leaves the server unencrypted.

## Verify encryption

```bash
sudo make verify
```

Manual check:

```bash
cd /
git clone /etc /tmp/etc-test
grep -R "root:" /tmp/etc-test/shadow || echo "OK: encrypted"
```

Expected: unreadable `shadow`.

## Restore on new system

```bash
sudo apt-get install git etckeeper git-crypt
sudo git clone <repo> /etc
cd /etc
sudo git-crypt import-key /path/to/etc-git-crypt.key
sudo etckeeper init
```

## Reset repo (danger)

```bash
cd /etc
sudo make clean
```

Deletes `.git`.

## Summary

| Action | Command |
|--------|--------|
Initialize | `sudo make secure-init` |
Export key | `sudo git-crypt export-key /root/etc-git-crypt.key` |
Set GitHub remote | `sudo make set-remote` |
Push encrypted backup | `sudo make backup-remote` |
Verify encryption | `sudo make verify` |
Reset repo | `sudo make clean` |

## Reminder

> **If you lose the git-crypt key, you lose access to `/etc` backups.**
> Back it up safely. Test restore procedure once.
