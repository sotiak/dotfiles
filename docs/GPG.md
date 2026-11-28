# GPG鍵管理

YubiKey 5 NFC を中心に GPG 鍵を管理している。

| Use case | Key capability | Key location |
| --- | --- | --- |
| GitHub への push | -（HTTPS + `gh` OAuth） | - |
| GitHub commit/tag signing | `[S]` signing | ローカル per-device サブキー（Windows keyring） |
| SOPS の復号 | -（age） | `~/.config/sops/age/keys.txt` |
| その他の GPG 暗号 | `[E]` encryption | YubiKey 5 NFC |
| OpenPGP key management | `[C]` certification | YubiKey 5 NFC |

GitHub の SSH authentication には `[A]` を使わない。GitHub は HTTPS + `gh` の OAuth トークン。
`[A]` は Windows ネイティブ SSH のバックアップとして残すだけ。
5C Nano は使わない。

GnuPG home は XDG data directory に置く。

```plaintext
~/.local/share/gnupg
```

## Windows 端末

- Git commit/tag 署名用のローカル `[S]` サブキーを置く。
- 端末ごとに別の署名サブキーを持たせる。端末をなくした場合は、その端末の署名サブキーだけを失効する。
- YubiKey 5 NFC の `[C]` / `[E]` / `[A]` はバックアップ・その他の暗号用。開発マシンの GitHub / 署名 / SOPS では使わない。

WSL の Git 署名は Windows 側 Gpg4win を呼ぶ。

```plaintext
/mnt/c/Program Files/GnuPG/bin/gpg.exe
```

PIN は Windows gpg-agent がキャッシュする（`default-cache-ttl 34560000`）。
YubiKey は不要で、タッチも不要。

## WSL

WSL では Windows 側の GnuPG を使う。WSL 側の `gpg` は公開鍵の確認用で、カードは読まない。

```plaintext
~/.local/share/gnupg
```

- `gpg --card-status` は WSL では失敗してよい。
- カード操作は Windows 側 `gpg.exe` で行う。5 NFC を Windows に挿す。
- SOPS は age。GPG `[E]` は使わない。

## SOPS は age

SOPS の復号には age のローカル鍵を使う。secret は `home-infra` リポジトリにある。

```plaintext
~/.config/sops/age/keys.txt
```

- `home-infra/.sops.yaml` に WSL の age 公開鍵を登録済み
- macOS の age 公開鍵を追加したら `pgp:` の recipient を外す
- `sops.age.keyFile` と `SOPS_AGE_KEY_FILE` は `~/.config/sops/age/keys.txt`
- 既存の PGP secret は、5 NFC を Windows に挿した状態で一度だけ移行する

```bash
cd ~/repositories/github.com/sotiak/home-infra
SOPS_GPG_EXEC='/mnt/c/Program Files/GnuPG/bin/gpg.exe' \
  sops updatekeys secrets/example.yaml
```

移行後は 5 NFC を挿さなくてよい。`SOPS_GPG_EXEC` は移行時だけ使う。

## GitHub で使うもの

GitHub の push は HTTPS + `gh` の OAuth トークン。

```bash
gh auth login -h github.com -p https -w
gh auth status
```

GitHub の commit signature は GPG の主キー fingerprint で検証される。
`config/git/config` の `user.signingkey` は主キー fingerprint のまま。

```plaintext
30B3D66B945D4F401B63338C0D24BF6D3FBDACB0
```

署名サブキーを追加または失効したら、公開鍵ブロックを再exportしてGitHubへ登録し直す。

```plaintext
gpg --armor --export 30B3D66B945D4F401B63338C0D24BF6D3FBDACB0 > github-gpg-public.asc
```

## Gitで使うもの

- Gitには、端末用署名サブキーではなく主キーfingerprintを指定する。
  - サブキーfingerprintにはしない。`!` も付けない。
- WSLでは、Windows側のGpg4winを使う。
- GitHubへのpushはSSHではなくHTTPS + `gh`。

## 5 NFC のその他の用途

- phone の FIDO2 / passkey（NFC）
- OATH / OTP
- GPG `[E]` を使うその他の暗号（メール・ファイル）
- GPG `[C]` / `[A]` のバックアップ

GPG `[E]` を使うときだけ 5 NFC を Windows に挿す。UIF off + PIN キャッシュでタッチは不要。
SOPS では使わない。

## バックアップ

下記は別途バックアップを作成している。

- primary-secret-full-backup.asc
  - 主キーの秘密鍵。YubiKey交換など、移行時に使う。
- primary-revocation.asc
  - 主キーを失効するための証明書。鍵漏洩時などに使う。

端末用署名サブキーの秘密鍵は基本バックアップせず、割とカジュアルに失効・再発行する。
age の秘密鍵 `~/.config/sops/age/keys.txt` は別途バックアップする。

## 端末移行時

新しい端末では、Home Manager適用後にYubiKeyから公開鍵URLを読み、公開鍵importとsmartcard stub作成を行う。
`gpg --card-edit`の`fetch`は、カードに登録された`URL of public key`から公開鍵を取得する。
カード操作は Windows 側 `gpg.exe` で行う。

```plaintext
"/mnt/c/Program Files/GnuPG/bin/gpg.exe" --card-edit
gpg/card> fetch
gpg/card> quit
```

repository内の公開鍵ファイルからimportする場合は下記を使う。

```plaintext
gpg --import ./keys/openpgp/sotiak.asc
```

新しい端末用の署名サブキーを発行する。

```plaintext
gpg --quick-add-key 30B3D66B945D4F401B63338C0D24BF6D3FBDACB0 ed25519 sign never
```

新しい `[S]` サブキーが追加され、`>` が付いていなければ、その端末上に秘密サブキーがある。

SOPS 用の age 鍵は端末ごとに作る。

```plaintext
age-keygen -o ~/.config/sops/age/keys.txt
```

公開鍵を `.sops.yaml` の `age:` に追加する。
