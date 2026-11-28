# WSL

WSL では、用途ごとに経路を分ける。

| 用途 | 経路 | YubiKey |
| --- | --- | --- |
| GitHub への push | HTTPS + `gh` の OAuth トークン | 不要 |
| Git の commit/tag 署名 | Windows 側 GnuPG のローカル `[S]` | 不要 |
| SOPS の復号 | age のローカル鍵 | 不要 |
| VM への SSH | Tailscale SSH | 不要 |

YubiKey 5 NFC は、phone の FIDO2 / OATH、GPG 鍵のバックアップとして持ち歩く。
開発マシンの GitHub・署名・SOPS・VM SSH では使わない。5C Nano も使わない。

## GitHub は HTTPS

SSH 鍵ではなく、`gh auth login` の OAuth トークンを使う。

```bash
gh auth login -h github.com -p https -w
gh auth status
```

`credential.https://github.com.helper` は `!gh auth git-credential` にしてある。
`gh` のトークンは `~/.config/gh/hosts.yml`（mode 600）に保存される。

```bash
git remote -v                  # origin は https://github.com/...
git ls-remote origin HEAD      # 認証確認
```

- PAT ではない。不要になったら `gh auth logout` で失効する
- paseo 配下のエージェントも `~/.config/gh/hosts.yml` と `gh` ヘルパーを使う
- GitHub の SSH 鍵はフォールバックとして残してよい。WSL の git は使わない

## Git 署名と SOPS

Git 署名は Windows 側 GnuPG のローカル `[S]` サブキー。

```bash
git config --show-origin --get gpg.program
git config --show-origin --get user.signingkey
```

- `gpg.program` は `/mnt/c/Program Files/GnuPG/bin/gpg.exe`
- PIN は Windows gpg-agent がキャッシュする（`default-cache-ttl 34560000`）
- YubiKey は不要。タッチも不要

SOPS は age のローカル鍵。secret は `home-infra` リポジトリにある。

```bash
cd ~/repositories/github.com/sotiak/home-infra
sops --decrypt secrets/example.yaml
```

- 鍵は `~/.config/sops/age/keys.txt`（mode 600）
- `SOPS_AGE_KEY_FILE` は `~/.config/sops/age/keys.txt`
- `home-infra/.sops.yaml` に WSL の age 公開鍵を登録済み
- 既存の PGP secret は、5 NFC を Windows に挿した状態で一度だけ移行する

```bash
cd ~/repositories/github.com/sotiak/home-infra
SOPS_GPG_EXEC='/mnt/c/Program Files/GnuPG/bin/gpg.exe' \
  sops updatekeys secrets/example.yaml
```

移行後は 5 NFC を挿さなくてよい。
macOS の age 公開鍵を `home-infra/.sops.yaml` に追加したら、`pgp:` の recipient は外す。

## VM への SSH

VM は Tailscale SSH で入る。SSH 鍵も agent も不要。

```bash
ssh monitoring-01
```

- `tailscale status` で tailnet のホストを確認する
- Tailscale の ACL が許可するユーザーで入る。`sk` が拒否される場合は `root` など ACL のユーザーを使う
- `SSH_AUTH_SOCK` は設定しない。`ssh-add -l` は「no agent」で正常

## YubiKey 5 NFC

開発マシンでは使わない。持ち歩き用。

- phone の FIDO2 / passkey（NFC）
- OATH / OTP
- GPG 鍵のバックアップ（`[C]` / `[E]` / `[A]`）

SOPS と GitHub と Git 署名では使わない。
5C Nano は使わない。

## 前提: WSLInterop

Windows の `gpg.exe` を WSL から呼ぶため、interop が必要。

```bash
/mnt/c/Windows/System32/cmd.exe /C "echo ok"
cat /proc/sys/fs/binfmt_misc/WSLInterop
```

`protectBinfmt = false` にして、NixOS の `systemd-binfmt` に登録を任せている。
`nixos-rebuild switch` の後や `wsl --shutdown` の後に確認する。

## 旧経路

以下は削除済み。

- Windows OpenSSH agent の relay（`socat` + `npiperelay`）
- NixOS-WSL の `wsl.ssh-agent`
- `usbip` / `pcscd` / `pcsc-tools`
- FIDO2 の SSH 鍵 / `SSH_SK_HELPER`
- WSL の gpg-agent SSH support

`~/.ssh/agent.sock` や古い `~/.ssh/config` の symlink が残っていれば削除する。
WSL の `gpg --card-status` は失敗してよい。カード操作は Windows 側 gpg で行う。
