SHELL=/bin/bash

.PHONY: check-tools init-git add-attributes init-gitcrypt init-etckeeper encrypted-commit echo-key verify clean secure-init

TOOLS = git etckeeper git-crypt

check-tools:
	@echo "[*] Checking required tools..."
	@for t in $(TOOLS); do \
		if ! command -v $$t >/dev/null 2>&1; then \
			echo "[-] $$t missing — installing"; \
			apt-get update && apt-get install -y $$t; \
		else \
			echo "[+] $$t OK"; \
		fi; \
	done

init-git:
	@if [ -d .git ]; then echo "[!] .git already exists — aborting"; exit 1; fi
	@echo "[*] Initializing bare git repo (no sensitive data committed yet)"
	git init

add-attributes:
	@echo "[*] Adding .gitattributes to enable encryption filters"
	git add .gitattributes
	git commit -m "Add git-crypt filters before initial commit"

init-gitcrypt:
	@echo "[*] Initializing git-crypt"
	git-crypt init

init-etckeeper:
	@echo "[*] Initializing etckeeper WITHOUT its initial auto-commit"
	AVOID_COMMIT_BEFORE_INSTALL=1 etckeeper init

encrypted-commit:
	@echo "[*] Creating first encrypted commit of /etc"
	git add -A
	git commit -m "Initial encrypted commit of /etc"

echo-key:
	@echo ""
	@echo "================================================================"
	@echo " git-crypt symmetric key created."
	@echo ""
	@echo " To export it securely for backup:"
	@echo ""
	@echo "     git-crypt export-key /root/etc-git-crypt.key"
	@echo ""
	@echo " Store this key OFF the machine (USB, password manager, vault)."
	@echo " Without this key you CANNOT decrypt the repo later."
	@echo "================================================================"
	@echo ""

verify:
	@echo "[*] Verifying encryption"
	@git-crypt status | grep encrypted >/dev/null && echo "[+] git-crypt active" || echo "[-] ERROR: git-crypt NOT active!"
	@echo "[*] Checking shadow is encrypted (should NOT be readable)"
	@if git show HEAD:shadow 2>/dev/null | grep -q "root:" ; then \
		echo "[-] ERROR: /etc/shadow appears readable — encryption failed!"; exit 1; \
	else \
		echo "[+] /etc/shadow appears encrypted"; \
	fi

clean:
	@echo "[!] Removing .git — only use if you want to reset"
	rm -rf .git
	echo "[OK] repo removed"

secure-init: check-tools init-git add-attributes init-gitcrypt init-etckeeper encrypted-commit echo-key verify
	@echo "[OK] Secure encrypted /etc Git repo initialized"


.PHONY: backup-remote set-remote show-remote

set-remote:
	@echo "Enter your private GitHub repo URL (example: git@github.com:USERNAME/etc-backup.git)"
	@read -p "Remote URL: " url; \
	git remote add origin $$url && echo "[+] Remote added: $$url" || echo "[!] Remote already exists"

show-remote:
	@echo "[*] Current git remotes:"
	git remote -v || echo "[!] No remote configured"

backup-remote:
	@echo "[*] Checking git-crypt status..."
	@if ! git-crypt status 2>/dev/null | grep -q "encrypted"; then \
		echo "[!] ERROR: git-crypt not active — refusing to push unencrypted data"; exit 1; \
	fi

	@echo "[*] Ensuring remote exists..."
	@if ! git remote -v | grep -q origin; then \
		echo "[!] No origin remote configured. Run:"; \
		echo ""; \
		echo "   make set-remote"; \
		echo ""; \
		exit 1; \
	fi

	@echo "[*] Committing changes before push"
	git add -A
	git commit -m "Automated encrypted backup" || echo "[i] Nothing to commit"

	@echo "[*] Pushing encrypted /etc to remote"
	git push origin master --force

	@echo ""
	@echo "=============================================================="
	@echo "✅ Encrypted backup pushed to private GitHub repo"
	@echo "⚠️ REMEMBER: GitHub does NOT store your decryption key"
	@echo "   Export & store it somewhere safe:"
	@echo ""
	@echo "       git-crypt export-key /root/etc-git-crypt.key"
	@echo ""
	@echo "   Then move it OFF this server!"
	@echo "=============================================================="
