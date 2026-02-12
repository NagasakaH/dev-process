# マルチリポジトリコミット除外ルール

コミット時に自動的に除外されるファイルとディレクトリのルール定義です。

## 除外カテゴリ

### 1. ビルド成果物

コンパイル・ビルドによって生成されるファイル。

| パターン | 説明 | 対象言語/ツール |
|----------|------|----------------|
| `dist/` | ビルド出力ディレクトリ | JavaScript/TypeScript |
| `build/` | ビルド出力ディレクトリ | 汎用 |
| `target/` | ビルド出力ディレクトリ | Rust, Java/Maven |
| `out/` | ビルド出力ディレクトリ | 汎用 |
| `bin/` | バイナリ出力ディレクトリ | C#, Go, C/C++ |
| `obj/` | オブジェクトファイル | C#, C/C++ |
| `*.o` | オブジェクトファイル | C/C++ |
| `*.a` | 静的ライブラリ | C/C++ |
| `*.so` | 共有ライブラリ | Linux |
| `*.dll` | ダイナミックリンクライブラリ | Windows |
| `*.exe` | 実行ファイル | Windows |
| `*.class` | コンパイル済みJavaクラス | Java |
| `*.jar` | Javaアーカイブ | Java |
| `*.pyc` | コンパイル済みPython | Python |
| `*.pyo` | 最適化済みPython | Python |

### 2. ログファイル

アプリケーションやツールが生成するログ。

| パターン | 説明 |
|----------|------|
| `*.log` | 一般的なログファイル |
| `*.log.*` | ローテーションされたログ |
| `logs/` | ログディレクトリ |
| `npm-debug.log*` | npmデバッグログ |
| `yarn-debug.log*` | Yarnデバッグログ |
| `yarn-error.log*` | Yarnエラーログ |
| `pnpm-debug.log*` | pnpmデバッグログ |
| `lerna-debug.log*` | Lernaデバッグログ |

### 3. 一時ファイル

OS やエディタが生成する一時ファイル。

| パターン | 説明 | 生成元 |
|----------|------|--------|
| `.DS_Store` | macOS フォルダメタデータ | macOS |
| `Thumbs.db` | Windowsサムネイルキャッシュ | Windows |
| `Desktop.ini` | Windowsフォルダ設定 | Windows |
| `*.swp` | Vimスワップファイル | Vim |
| `*.swo` | Vimスワップファイル | Vim |
| `*~` | バックアップファイル | 各種エディタ |
| `*.bak` | バックアップファイル | 汎用 |
| `*.tmp` | 一時ファイル | 汎用 |
| `*.temp` | 一時ファイル | 汎用 |
| `.#*` | Emacsロックファイル | Emacs |
| `#*#` | Emacs自動保存 | Emacs |

### 4. 環境変数ファイル

機密情報を含む可能性のある環境設定ファイル。

| パターン | 説明 |
|----------|------|
| `.env` | 環境変数ファイル |
| `.env.local` | ローカル環境変数 |
| `.env.development` | 開発環境変数 |
| `.env.development.local` | ローカル開発環境変数 |
| `.env.test` | テスト環境変数 |
| `.env.test.local` | ローカルテスト環境変数 |
| `.env.production` | 本番環境変数 |
| `.env.production.local` | ローカル本番環境変数 |
| `.env.*.local` | ローカル環境変数（全パターン） |
| `*.pem` | 証明書/秘密鍵 |
| `*.key` | 秘密鍵ファイル |
| `*.p12` | PKCS#12証明書 |
| `*.pfx` | PKCS#12証明書 |

### 5. 依存関係ディレクトリ

パッケージマネージャが管理する依存関係。

| パターン | 説明 | 言語/ツール |
|----------|------|-------------|
| `node_modules/` | npm/yarn依存関係 | JavaScript/TypeScript |
| `venv/` | Python仮想環境 | Python |
| `.venv/` | Python仮想環境 | Python |
| `virtualenv/` | Python仮想環境 | Python |
| `vendor/` | 依存関係（ベンダリング） | PHP, Go, Ruby |
| `packages/` | 依存パッケージ | 一部のプロジェクト |
| `.bundle/` | Bundlerメタデータ | Ruby |
| `bower_components/` | Bower依存関係 | JavaScript（レガシー） |
| `.gradle/` | Gradleキャッシュ | Java/Kotlin |
| `.m2/` | Mavenローカルリポジトリ | Java |

### 6. キャッシュディレクトリ

ビルドツールやランタイムのキャッシュ。

| パターン | 説明 | 生成元 |
|----------|------|--------|
| `.cache/` | 一般的なキャッシュ | 汎用 |
| `__pycache__/` | Pythonバイトコードキャッシュ | Python |
| `.pytest_cache/` | pytestキャッシュ | Python/pytest |
| `.mypy_cache/` | mypyキャッシュ | Python/mypy |
| `.ruff_cache/` | Ruffキャッシュ | Python/Ruff |
| `.tox/` | toxキャッシュ | Python/tox |
| `.nx/` | Nxキャッシュ | Nx |
| `.turbo/` | Turboキャッシュ | Turborepo |
| `.parcel-cache/` | Parcelキャッシュ | Parcel |
| `.next/` | Next.jsビルドキャッシュ | Next.js |
| `.nuxt/` | Nuxtビルドキャッシュ | Nuxt.js |
| `.svelte-kit/` | SvelteKitビルドキャッシュ | SvelteKit |
| `.angular/` | Angularキャッシュ | Angular |
| `.eslintcache` | ESLintキャッシュ | ESLint |
| `.stylelintcache` | Stylelintキャッシュ | Stylelint |
| `coverage/` | テストカバレッジレポート | 各種テストツール |
| `.nyc_output/` | NYC カバレッジ出力 | NYC |

### 7. IDE設定

IDE やエディタのプロジェクト設定。

| パターン | 説明 | IDE |
|----------|------|-----|
| `.vscode/` | VS Code設定 | VS Code |
| `.idea/` | JetBrains IDE設定 | IntelliJ, WebStorm等 |
| `*.iml` | IntelliJ Moduleファイル | JetBrains |
| `*.ipr` | IntelliJ Projectファイル | JetBrains |
| `*.iws` | IntelliJ Workspaceファイル | JetBrains |
| `.project` | Eclipse プロジェクト設定 | Eclipse |
| `.classpath` | Eclipse クラスパス | Eclipse |
| `.settings/` | Eclipse設定 | Eclipse |
| `*.sublime-project` | Sublimeプロジェクト | Sublime Text |
| `*.sublime-workspace` | Sublimeワークスペース | Sublime Text |
| `.atom/` | Atom設定 | Atom |

**例外:**
- `.vscode/settings.json` がチームで共有される設定の場合は除外しない
- `.vscode/extensions.json` は推奨拡張機能として除外しないことも可能

### 8. テンポラリディレクトリ

一時的なファイル保存用ディレクトリ。

| パターン | 説明 |
|----------|------|
| `tmp/` | 一時ディレクトリ |
| `temp/` | 一時ディレクトリ |
| `/tmp/` | システム一時ディレクトリ参照 |
| `/temp/` | 一時ディレクトリ参照 |

## 判定ロジック

### パターンマッチング優先順位

1. **完全一致** - ファイル名が完全に一致
2. **ディレクトリマッチ** - 親ディレクトリが除外対象
3. **拡張子マッチ** - ファイル拡張子が除外対象
4. **プレフィックスマッチ** - ファイル名先頭が除外対象
5. **サフィックスマッチ** - ファイル名末尾が除外対象

### 判定例

```
src/utils.ts                    --> ✅ ステージング対象
node_modules/lodash/index.js    --> ❌ 除外（依存関係ディレクトリ）
dist/bundle.js                  --> ❌ 除外（ビルド成果物）
.env.local                      --> ❌ 除外（環境変数ファイル）
.DS_Store                       --> ❌ 除外（一時ファイル）
docs/README.md                  --> ✅ ステージング対象
__pycache__/module.pyc          --> ❌ 除外（キャッシュ）
```

## カスタマイズ

### プロジェクト固有の除外ルール

`.gitignore` に記載されているパターンも除外対象として考慮してください：

```bash
# .gitignore の内容を確認
cat .gitignore
```

### 除外対象から復帰させる場合

ユーザーが明示的に含めたいファイルを指定した場合は、除外ルールより優先：

```
ユーザー: "dist/custom-bundle.js は含めてください"
--> dist/custom-bundle.js は除外せずステージング
```

## 報告フォーマット

除外結果の報告時は以下のフォーマットを使用：

```
❌ 除外されたファイル（{合計数}件）:

  [ビルド成果物]
    - dist/bundle.js
    - dist/bundle.js.map
  
  [依存関係ディレクトリ]
    - node_modules/（ディレクトリ全体）
  
  [一時ファイル]
    - .DS_Store
  
  [キャッシュ]
    - .eslintcache
    - .next/（ディレクトリ全体）
```

## 更新履歴

| 日付 | 変更内容 |
|------|---------|
| 初版 | 基本除外ルールを定義 |
