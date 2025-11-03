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

## Installation Instructions

This section explains how to install the secure `/etc` backup system using this repository, which contains:

- `Makefile` (automation commands)
- `.gitattributes` (encryption rules)
- `README.md` (documentation)

The objective is to safely install these files into `/etc` **before initializing Git**, so that no sensitive file ever enters history unencrypted.

---

### ⚠️ Important Security Reminder

Do **not** run `git init` inside `/etc` before copying the files.  
The `.gitattributes` file must exist **before the first commit**, otherwise secrets could be committed in plaintext.

---

### 1. Clone this repository (in a temporary location)

Use HTTPS:

```bash
cd /root
git clone https://github.com/molinerisLab/securEtcBackup.git
```

Or SSH:

```bash
cd /root
git clone git@github.com:molinerisLab/securEtcBackup.git
```

---

### 2. Copy `.gitattributes` and `Makefile` into `/etc`

```bash
cd securEtcBackup
cp .gitattributes /etc/
cp Makefile /etc/
```

---

### 3. Initialize secure `/etc` versioning

Now that the encryption rules and make commands are in place, you can safely initialize:

```bash
cd /etc
sudo make secure-init
```

This will:

- Initialize Git
- Register encryption filters
- Enable `git-crypt`
- Initialize `etckeeper` without clear‑text commit
- Create the first fully encrypted commit
- Verify `/etc/shadow` is encrypted

---

### 4. Export the symmetric key (required!)

```bash
sudo git-crypt export-key /root/etc-git-crypt.key
sudo chmod 600 /root/etc-git-crypt.key
```

Store this key **off‑machine**:

- Offline USB
- Password manager
- Encrypted vault

If you lose it, you **cannot decrypt** your `/etc` history.

---

### 5. (Optional) Push encrypted backup to GitHub

```bash
sudo make set-remote
sudo make backup-remote
```

> Ensure your remote repo is **private**.

---

### ✅ Done!

Your `/etc` is now securely versioned, encrypted, and backup‑ready.

You can trigger remote encrypted backups anytime with:

```bash
sudo make backup-remote
```

---

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
