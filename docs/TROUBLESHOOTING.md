## WSLでWindows側のバイナリが実行できなくなる

`WSLInterop` が無効になると、`gpg.exe` などの Windows バイナリを WSL から実行できない。

```
❯ /mnt/c/Windows/System32/cmd.exe /C "echo ok"
zsh: exec format error: /mnt/c/Windows/System32/cmd.exe
❯ cat /proc/sys/fs/binfmt_misc/WSLInterop
cat: /proc/sys/fs/binfmt_misc/WSLInterop: No such file or directory
```

原因は WSL の `protectBinfmt` が `systemd-binfmt` を上書きすることだ。
`nixos-rebuild` が `binfmt_misc` を remount したときに、登録が消える。

WSL 側では `wsl.wslConf.boot.protectBinfmt = false` にして、
NixOS の `systemd-binfmt` に `WSLInterop` と `aarch64` を登録させている。

確認:

```bash
cat /proc/sys/fs/binfmt_misc/WSLInterop
ls /proc/sys/fs/binfmt_misc/
```

`WSLInterop` と `aarch64-linux` があればよい。
`/etc/wsl.conf` の `[boot] protectBinfmt=false` は `wsl --shutdown` 後に反映される。

`wsl-fix-interop` は削除した。旧スクリプトは `/usr/lib/binfmt.d` に書いていたが、
NixOS にはそのディレクトリが無く、mask も残るため使わない。

`nixos-rebuild switch` で `systemd-binfmt` が失敗する場合は、
一時的に `boot.binfmt.emulatedSystems` を外して switch する。
`wsl --shutdown` 後に戻して switch する。

## Git 署名が失敗する

WSL の git は Windows 側の `gpg.exe` を呼ぶ。

```bash
git config --show-origin --get gpg.program
git config --show-origin --get user.signingkey
"/mnt/c/Program Files/GnuPG/bin/gpg.exe" --version
```

`gpg.exe` が実行できないなら、先に WSLInterop を直す。
`[S]` は Windows keyring のローカルサブキー。YubiKey は不要。

## GitHub の push が認証で失敗する

HTTPS + `gh` の OAuth トークンを使う。

```bash
gh auth status
git config --show-origin --get-all 'credential.https://github.com.helper'
git remote -v
```

- `gh` が `Logged in to github.com account ...` ならよい
- `credential.https://github.com.helper` が `!gh auth git-credential` ならよい
- remote が `https://github.com/...` ならよい
- 失敗したら `gh auth login -h github.com -p https -w`
- paseo から失敗する場合は `~/.config/gh/hosts.yml` の権限と `HOME` を確認する

## SOPS の復号が失敗する

age のローカル鍵を使う。secret は `home-infra` リポジトリにある。

```bash
cd ~/repositories/github.com/sotiak/home-infra
cat ~/.config/sops/age/keys.txt
echo "$SOPS_AGE_KEY_FILE"
sops --decrypt secrets/example.yaml
```

- `home-infra/.sops.yaml` の `age:` に WSL の公開鍵があるか
- `SOPS_AGE_KEY_FILE` が `~/.config/sops/age/keys.txt` を指しているか
- `secrets/monitoring.yaml` は monitoring VM の host key のみ。WSL では復号できない
- 既存の PGP secret を移行していない場合は、5 NFC を Windows に挿して
  `SOPS_GPG_EXEC='/mnt/c/Program Files/GnuPG/bin/gpg.exe' sops updatekeys ...`
- 移行後は 5 NFC も `SOPS_GPG_EXEC` も不要

## Tailscale SSH が拒否される

```
tailscale: tailnet policy does not permit you to SSH as user "sk"
```

Tailscale の ACL が許可するユーザーで入る。

```bash
ssh root@monitoring-01
tailscale status
```

`SSH_AUTH_SOCK` は設定しない。`ssh-add -l` が「no agent」でも正常。

## YubiKey のカード操作

WSL の `gpg --card-status` は失敗してよい。
カード操作は Windows 側 `gpg.exe` で行う。

```bash
"/mnt/c/Program Files/GnuPG/bin/gpg.exe" --card-status
```

5 NFC を Windows に挿す。5C Nano は使わない。
SOPS と GitHub と Git 署名では 5 NFC を挿さない。

## 旧経路の残骸

以下は使わない。

- `~/.ssh/agent.sock`
- `windows-ssh-agent-relay`
- `wsl2-ssh-agent`
- `pcscd` / `usbip` / `pcsc_scan`
- FIDO2 の SSH 鍵 / `SSH_SK_HELPER`

`env | grep SSH_AUTH_SOCK` が空で、`systemctl status pcscd` が not found ならよい。
