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
