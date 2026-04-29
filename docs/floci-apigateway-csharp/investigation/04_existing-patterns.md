# 既存パターン調査

## 概要

既存リポジトリは .NET 8 / xUnit / GitLab CI に統一されたパターンを持ち、ローカル⇔CI で同形のシェルスクリプト化されたフローを採用している。Angular 側は Angular CLI が生成する標準パターン（Karma + Jasmine, ESLint）を踏襲しつつ、CI ジョブ命名は既存の `lint/unit/integration/e2e` ステージ命名に合わせて `web-lint / web-unit / web-integration / web-e2e` とする決定が既にされている。

## コーディングスタイル

### 既存（バックエンド）
| ファイル | 内容 |
|----------|------|
| `.editorconfig` | 既存。改行・インデント等を統一 |
| `dotnet format` | `lint` ステージで `--verify-no-changes` |
| `Nullable enable` / `ImplicitUsings enable` | csproj 既定 |

### 追加予定（フロント）
| ファイル | 内容 |
|----------|------|
| `frontend/.editorconfig` | リポジトリ既存と整合 |
| `frontend/eslint.config.js` (or `.eslintrc.json`) | `@angular-eslint/recommended` |
| `frontend/.prettierrc` (任意) | スタイル統一 |
| `frontend/tsconfig.json` | Angular 18 既定（strict 推奨） |

### 命名規則（フロント）
| 対象 | 規則 | 例 |
|------|------|-----|
| ファイル名 | kebab-case | `todo-api.service.ts` |
| クラス名 | PascalCase | `TodoApiService` |
| 関数名 | camelCase | `createTodo` |
| 定数 | UPPER_SNAKE_CASE | `API_BASE_URL_KEY` |

## 既存実装パターン（参考）

### Lambda エントリポイント (`Function.cs`)
- 単一クラス内で HTTP メソッド + path で if 分岐するシンプル構成
- レスポンス生成は `private static APIGatewayProxyResponse BadRequest/NotFound(...)` ヘルパに集約
- ヘッダは `JsonHeaders` 共通辞書で統一 → **CORS 追加時は同辞書 or 別ヘルパで一元管理するのが自然**

```csharp
private static readonly Dictionary<string, string> JsonHeaders = new()
{
    ["Content-Type"] = "application/json; charset=utf-8",
};
```

### Repository パターン
- Lazy 初期化された Repository / Client を Function コンストラクタで保持
- テスト用にコンストラクタオーバーロードで DI 可能（`internal Function(ITodoRepository, IAmazonStepFunctions, string)`）

### バリデーション
- `Validation/TodoValidator` を独立クラス化、Unit テスト (`TodoValidatorTests`) と整合

## テストパターン

### 既存テストファイル配置（バックエンド）
```
tests/
├── TodoApi.UnitTests/         # 依存無し, Moq でモック
├── TodoApi.IntegrationTests/  # FlociFixture で floci 起動を検出, SkipIfNoFlociFact で skip
└── TodoApi.E2ETests/          # E2EFixture で API_BASE_URL を環境変数から取得
```

### Skip パターン（重要）
- `tests/TodoApi.IntegrationTests/SkipIfNoFlociFact.cs` により floci が無い環境では自動 skip → CI と開発者ローカル双方で安全
- フロント E2E でも同様に「`API_BASE_URL` 未設定なら skip / fail-fast」のパターン踏襲が望ましい

### 追加予定（フロント）
```
frontend/
├── src/app/
│   ├── todo.component.ts
│   ├── todo.component.spec.ts          # Karma + Jasmine 単体
│   ├── services/todo-api.service.ts
│   ├── services/todo-api.service.spec.ts  # HttpTestingController で結合
│   └── services/config.service.spec.ts
├── playwright.config.ts
└── e2e/
    └── todo.spec.ts                     # Playwright E2E
```

### 単体テストパターン例（Karma + Jasmine）
```typescript
describe('TodoApiService', () => {
  let svc: TodoApiService;
  let http: HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [HttpClientTestingModule],
      providers: [
        TodoApiService,
        { provide: ConfigService, useValue: { apiBaseUrl: 'http://api' } },
      ],
    });
    svc = TestBed.inject(TodoApiService);
    http = TestBed.inject(HttpTestingController);
  });

  it('POST /todos を呼ぶ', () => {
    svc.create({ title: 'milk' }).subscribe();
    const req = http.expectOne('http://api/todos');
    expect(req.request.method).toBe('POST');
    req.flush({ id: '1', title: 'milk' });
  });
});
```

## CI ジョブパターン

### 既存ステージ
```yaml
stages:
  - lint
  - unit
  - integration
  - e2e
```

### 既存パターン（重要観察点）
- **`.dotnet` テンプレート**を `extends:` で再利用 → フロント側も `.node` テンプレート化が良い
- **環境変数を variables: で全ジョブ固定** (`AWS_*`, `ENDPOINT`, `LAMBDA_ENDPOINT`) → フロントの `API_BASE_URL` は terraform output 由来のため、e2e ジョブ内で動的に取得する必要あり
- **`integration` / `e2e` は DinD 上で `docker compose up -d` してから dotnet test** → web-e2e でも同様パターン（floci 起動 → tf apply → frontend build → s3 配置 → nginx 起動 → playwright）が妥当
- **artifacts: junit** によるテストレポート集約 → frontend も `karma-junit-reporter` / `playwright reporter junit` で同形にする

### 追加ジョブ命名（ブレスト決定）
| ジョブ | ステージ | 主処理 |
|--------|---------|--------|
| `web-lint` | lint | `npm ci` → `npm run lint` (`ng lint`) |
| `web-unit` | unit | `npm ci` → `npm test -- --watch=false --browsers=ChromeHeadlessCI` |
| `web-integration` | integration | `npm ci` → HttpTestingController ベースの結合 spec 実行 |
| `web-e2e` | e2e | floci up → terraform apply → invoke_url 取得 → ng build → S3 同期 → nginx up → `npx playwright test` |

### Cache パターン（GitLab CI）
```yaml
cache:
  key:
    files: [frontend/package-lock.json]
  paths:
    - frontend/node_modules
    - .cache/ms-playwright
```

## エラーハンドリングパターン（既存）

- 4xx は `BadRequest(string[] errors)` / `NotFound(string)`
- 5xx は catch-all で `{ error: "internal error" }` + `ctx.Logger.LogError(ex.ToString())`
- フロント側もこの構造に合わせ、`ApiErrorResponse` (`errors[]` または `error`) を一律パースする実装が綺麗

## ロギングパターン（既存）

- `ILambdaContext.Logger.LogError` のみ（構造化ロガーなし）
- フロント側は `console.error` + UI 表示で十分（acceptance_criteria の「4xx/5xx 応答時にユーザ向けエラー表示」を満たす範囲）

## スクリプトパターン（既存）

- `scripts/deploy-local.sh`: floci 起動 → ヘルスチェック → `dotnet lambda package` → `terraform apply` を 1 ステップ idempotent 実行
- `scripts/warmup-lambdas.sh`: cold start 緩和（ENDPOINT 引数）
- `scripts/verify-*.sh`: README / CI YAML の整合チェック → **Angular 追加時もここに `verify-readme-sections.sh` を更新する必要あり**

### 追加予定スクリプト（想定）
| スクリプト | 役割 |
|------------|------|
| `scripts/build-frontend.sh` | invoke_url を config.json に注入 → `ng build` |
| `scripts/deploy-frontend.sh` | ビルド成果物を S3 (floci) へ `aws s3 sync` |
| `scripts/web-e2e.sh` | 上記 + nginx up + `npx playwright test` を 1 コマンド化 |

## 備考

- 「ローカル ⇔ CI で同じシェルスクリプトを使う」という強い文化があるため、フロント側のローカル/CI 統一スクリプトを最初から用意することが品質維持上重要。
- `verify-readme-sections.sh` 等の検証スクリプトに新セクション（`## 7. Frontend` 等）を追加する想定で、README 構造は破壊的変更を避ける。
