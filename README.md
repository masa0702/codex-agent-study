# Codex CLI 学習環境（macOS + Docker + VS Code Dev Containers）

Ubuntu 24.04、Node.js 24 LTS、Codex CLI、Python 3、Git を含む学習用コンテナです。
Codex は専用の非rootユーザー `codex` で実行します。

## ファイル構成

```text
codex-learning/
├── Dockerfile                    # Ubuntu + Node.js + Codex CLI
├── compose.yaml                  # Docker Compose とボリューム設定
├── .devcontainer/
│   └── devcontainer.json         # VS Code Dev Containers の接続設定
├── .dockerignore
├── .gitignore
├── workspace/                    # Codex に操作させる学習用フォルダ
│   └── README.md
└── README.md
```

## 1. 事前準備（macOS ホスト側）

- [Docker Desktop for Mac](https://www.docker.com/products/docker-desktop/) をインストール・起動する。
- [Visual Studio Code](https://code.visualstudio.com/) をインストールする。
- VS Code の拡張機能 `Dev Containers`（`ms-vscode-remote.remote-containers`）をインストールする。
- Apple Silicon と Intel Mac のどちらでも Docker が対象アーキテクチャを選択します。

macOS の「ターミナル」アプリで確認:

```bash
docker --version
docker compose version
docker info
```

最後のコマンドがエラーになる場合は、Docker Desktop が起動しているか確認してください。

## 2. フォルダを開く

ZIP を任意の場所に展開して `codex-learning` フォルダを作ります。
VS Code の「File > Open Folder...」から **`codex-learning`（workspace ではない）** を選んで開きます。

## 3. Docker 構成を検査する（任意）

VS Code のローカルターミナル、または macOS のターミナルで、`codex-learning` をカレントディレクトリとして以下を実行します。

```bash
docker compose config
docker compose build
```

初回ビルドはイメージと npm パッケージをダウンロードするため、ネット接続が必要です。

## 4. VS Code から Dev Container を起動する

1. VS Code で `codex-learning` フォルダを開いていることを確認します。
2. `⌘ + Shift + P` でコマンドパレットを開きます。
3. `Dev Containers: Reopen in Container` を選びます。
4. ビルド完了後、VS Code 左下に Dev Container 接続中の表示が出ます。
5. VS Code の「Terminal > New Terminal」を開きます。

コンテナ内ターミナルで確認:

```bash
whoami
pwd
node --version
codex --version
```

想定値:
- `whoami` → `codex`
- `pwd` → `/workspaces/codex-learning/workspace`
- Node.js → v24系
- Codex → インストールしたバージョン

## 5. ChatGPT アカウントで認証する

コンテナ内ターミナルで:

```bash
codex login --device-auth
```

表示された URL を Mac のブラウザで開き、ワンタイムコードを入力します。
この方式を利用するには、ChatGPT のセキュリティ設定で**デバイスコードによるログインを有効**にする必要があります。管理されたワークスペースでは管理者設定が必要な場合もあります。

完了後:

```bash
codex login status
```

認証データは `codex-home` という Docker の名前付きボリュームに置かれ、コンテナを再作成しても残ります。
`docker compose down -v` を実行するとボリュームごと消えるため注意してください。
認証トークンは秘密情報です。Git に登録したり、人に共有したりしないでください。

## 6. 最初の演習

```bash
git init
codex
```

Codex の画面に次の依頼を入力します。

> PythonでHello Worldを表示するファイルを作成し、実行して結果を示してください。

生成物が `workspace` 内に保存されることを VS Code のエクスプローラーで確かめます。
実行権限は Codex の初回設定や `/permissions` から確認してください。

## 7. 停止・再起動・更新

- 停止: VS Code コマンドパレット → `Dev Containers: Reopen Folder Locally`。必要に応じて `docker compose down`。
- 再開: フォルダを開き直して `Dev Containers: Reopen in Container`。
- Dockerfile/compose.yaml を編集した後: `Dev Containers: Rebuild Container`。
- Codex CLI を更新: `docker compose build --pull --no-cache` → `Dev Containers: Rebuild Container`。
- 作業ファイルは macOS の `workspace` に残ります。

## セキュリティ上の注意

- Docker ソケット、Mac のホームディレクトリ、SSH 鍵などはマウントしません。
- コンテナは非rootユーザーで実行し、全 Linux capability を削除して権限昇格を禁止しています。
- ただしインターネットへの通信は可能です。悪意あるコードの送信・実行を Docker 単体ですべて防げるわけではありません。
- Linux の Codex 内部サンドボックスは、Docker Desktop のカーネルや権限設定によって動かない場合があります。まず標準の `codex` で試し、動作しない場合はエラーメッセージを確認してください。
- 公式ドキュメントはコンテナの隔離を前提とした代替モードを説明していますが、Codex 内部の制限を解除するとコンテナ内の認証情報にも触れ得ます。学習開始時に自動的に制限解除しない構成です。
- この Compose 構成では、Codex の作業位置は `workspace` ですが、コンテナには `codex-learning` フォルダ全体がマウントされています。完全に実験領域を分離したい場合は別 Compose 構成に分離してください。

## トラブルシューティング

| 症状 | 対処 |
| --- | --- |
| `Cannot connect to Docker daemon` | Docker Desktop を起動して `docker info` で再確認 |
| `Dev Containers: Reopen in Container` が見当たらない | VS Code に Dev Containers 拡張機能を追加 |
| ビルド中のネットワークエラー | Docker Desktop と npm レジストリへの接続を確認し再実行 |
| `codex login --device-auth` が拒否される | ChatGPT セキュリティ設定でデバイスコード認証を有効化 |
| 再ログインが必要になった | `codex login status` と Docker ボリュームの残存を確認 |
| `sandbox` / `bwrap` のエラー | コンテナ内サンドボックスと Docker 権限制約の相性を確認し、エラー内容に応じて対策を検討 |

## 参考資料

- [Codex CLI（OpenAI）](https://github.com/openai/codex)
- [Codex CLI の認証方法（OpenAI）](https://learn.chatgpt.com/docs/auth?surface=cli)
- [Codex の承認・セキュリティ（OpenAI）](https://learn.chatgpt.com/docs/agent-approvals-security)
- [Create a Dev Container（VS Code）](https://code.visualstudio.com/docs/devcontainers/create-dev-container)
