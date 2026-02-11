# 情報抽出パターン定義

GitHub issueから情報を抽出するためのパターン定義です。

> **SSOT対応**: 抽出結果は階層化された description フォーマットで出力されます。

## 1. リポジトリリンク検出パターン

### 1.1 URL形式

```regex
# GitHub URL形式（完全URL）
https?:\/\/github\.com\/([a-zA-Z0-9_-]+)\/([a-zA-Z0-9_.-]+)(?:\/(?:issues|pull|tree|blob)\/[^\s]*)?

# マッチ例:
# - https://github.com/org/repo
# - https://github.com/org/repo/issues/123
# - https://github.com/user/my-project/tree/main/src
```

### 1.2 短縮形式

```regex
# owner/repo形式
(?:^|\s)([a-zA-Z0-9_-]+)\/([a-zA-Z0-9_.-]+)(?:\s|$|[,.:;)\]])

# マッチ例:
# - org/repo
# - user/my-project
# - company/api-server

# 除外パターン（ファイルパスと誤認しないため）
# - src/components
# - lib/utils
# - ./path/to
```

### 1.3 Git URL形式

```regex
# SSH形式
git@github\.com:([a-zA-Z0-9_-]+)\/([a-zA-Z0-9_.-]+)(?:\.git)?

# HTTPS Git形式
https:\/\/github\.com\/([a-zA-Z0-9_-]+)\/([a-zA-Z0-9_.-]+)\.git
```

## 2. 修正対象リポジトリの特定

### 2.1 キーワードベース検出

以下のキーワードの直後に出現するリポジトリを修正対象として特定：

```yaml
keywords:
  japanese:
    - "修正対象"
    - "対象リポジトリ"
    - "変更対象"
    - "修正箇所"
    - "実装先"
    - "修正先"
  english:
    - "target"
    - "affects"
    - "fix in"
    - "implement in"
    - "modify"
    - "change in"
```

### 2.2 パターン例

```markdown
# 検出される例
修正対象: org/backend-api
対象リポジトリ: https://github.com/org/frontend

# 検出ロジック
1. キーワードを検索
2. キーワード後の同一行または次行でリポジトリパターンを検索
3. 最初にマッチしたものを修正対象として採用
```

### 2.3 デフォルト動作

修正対象が明示されていない場合：
- **親リポジトリを使用** - issueが存在するリポジトリを修正対象とする

```yaml
# Issue URL: https://github.com/org/main-project/issues/123
# 修正対象が未指定の場合

target_repositories:
  - name: "main-project"
    url: "https://github.com/org/main-project"
```

## 3. 関連リポジトリの検出

### 3.1 キーワードベース検出

```yaml
keywords:
  japanese:
    - "関連"
    - "参照"
    - "依存"
    - "連携"
    - "参考"
  english:
    - "related"
    - "see also"
    - "reference"
    - "depends on"
    - "integration with"
```

### 3.2 ラベルからの検出

```yaml
label_patterns:
  # サブモジュール関連
  - pattern: "^submodule-(.+)$"
    extract: "$1"  # リポジトリ名として抽出
    
  # コンポーネント関連
  - pattern: "^component:(.+)$"
    extract: "$1"
    
  # プロジェクト関連
  - pattern: "^project:(.+)$"
    extract: "$1"
```

### 3.3 本文内リンクからの検出

修正対象として特定されなかったリポジトリリンクを関連リポジトリとして収集：

```python
# 疑似コード
all_repos = extract_all_repository_links(issue_body)
target_repos = extract_target_repositories(issue_body)
related_repos = all_repos - target_repos - parent_repo
```

## 4. description 階層化抽出パターン（SSOT対応）

### 4.1 セクションヘッダー検出パターン

Issue本文のセクションヘッダーを検出し、対応する description フィールドにマッピング：

```yaml
section_patterns:
  overview:
    patterns:
      - "^##\\s*(概要|Overview|Summary)"
      - "^###\\s*(概要|Overview|Summary)"
    priority: 1
    
  purpose:
    patterns:
      - "^##\\s*(目的|Purpose|Goal|Goals|Why)"
      - "^###\\s*(目的|Purpose|Goal)"
    priority: 2
    
  background:
    patterns:
      - "^##\\s*(背景|Background|Context|経緯|現状|Issue)"
      - "^###\\s*(背景|Background|Context)"
    priority: 3
    
  requirements:
    patterns:
      - "^##\\s*(要件|Requirements|仕様)"
      - "^##\\s*(機能要件|Functional\\s*Requirements)"
      - "^###\\s*(要件|Requirements)"
    priority: 4
    sub_sections:
      functional:
        patterns:
          - "^###\\s*(機能要件|Functional)"
          - "^####\\s*(機能要件|Functional)"
      non_functional:
        patterns:
          - "^###\\s*(非機能要件|Non-functional|NFR)"
          - "^####\\s*(非機能要件|Non-functional)"
    
  acceptance_criteria:
    patterns:
      - "^##\\s*(受け入れ条件|Acceptance\\s*Criteria|AC|完了条件|Done\\s*when|Definition\\s*of\\s*Done)"
      - "^###\\s*(受け入れ条件|Acceptance)"
    priority: 5
    
  scope:
    patterns:
      - "^##\\s*(スコープ|Scope|対象範囲|範囲)"
      - "^###\\s*(スコープ|Scope)"
    priority: 6
    
  out_of_scope:
    patterns:
      - "^##\\s*(スコープ外|Out\\s*of\\s*scope|対象外|除外|Non-scope)"
      - "^###\\s*(スコープ外|Out\\s*of\\s*scope)"
    priority: 7
    
  notes:
    patterns:
      - "^##\\s*(備考|Notes|補足|その他|参考|References)"
      - "^###\\s*(備考|Notes|補足)"
    priority: 8
```

### 4.2 セクション内容抽出ロジック

```javascript
function extractSectionContent(body, startPattern, endPatterns) {
  // セクション開始位置を検出
  const startMatch = body.match(startPattern);
  if (!startMatch) return null;
  
  const startIndex = startMatch.index + startMatch[0].length;
  
  // 次のセクションまたは文書末尾までを抽出
  let endIndex = body.length;
  for (const endPattern of endPatterns) {
    const endMatch = body.slice(startIndex).match(endPattern);
    if (endMatch && endMatch.index < endIndex) {
      endIndex = startIndex + endMatch.index;
    }
  }
  
  return body.slice(startIndex, endIndex).trim();
}
```

### 4.3 リスト項目の配列変換

```javascript
function extractListItems(sectionContent) {
  const listPattern = /^[-*]\s+(.+)$/gm;
  const checkboxPattern = /^[-*]\s*\[[ x]\]\s*(.+)$/gm;
  
  // チェックボックス形式を優先
  const checkboxMatches = [...sectionContent.matchAll(checkboxPattern)];
  if (checkboxMatches.length > 0) {
    return checkboxMatches.map(m => m[1].trim());
  }
  
  // 通常のリスト形式
  const listMatches = [...sectionContent.matchAll(listPattern)];
  return listMatches.map(m => m[1].trim());
}
```

## 5. フォールバック処理

### 5.1 構造化されていないissueの処理

```yaml
fallback_rules:
  # セクションが検出されない場合
  no_sections_detected:
    - action: "use_entire_body_as_overview"
      target: "description.overview"
      
    - action: "generate_purpose_from_title"
      target: "description.purpose"
      template: "{title} を実現する"
      
  # リスト形式のみの場合
  lists_without_sections:
    - action: "detect_checkbox_as_acceptance_criteria"
      pattern: "^[-*]\\s*\\[[ x]\\]"
      target: "description.acceptance_criteria"
      
    - action: "detect_regular_list_as_requirements"
      pattern: "^[-*]\\s+"
      target: "description.requirements.functional"
      
  # 最小限の情報しかない場合
  minimal_content:
    - action: "set_warning_flag"
      message: "Issue本文の構造化が不十分です。手動での補完を推奨します。"
```

### 5.2 フォールバック適用後の警告

```yaml
# フォールバック使用時に付与される警告
warnings:
  overview_from_full_body:
    message: "概要はIssue本文全体から抽出しました"
    action: "手動でセクション分割を検討してください"
    
  purpose_generated:
    message: "目的はタイトルから自動生成しました"
    action: "実際の目的を確認・修正してください"
    
  requirements_from_list:
    message: "要件はリスト項目から推測しました"
    action: "機能要件/非機能要件の分類を確認してください"
    
  acceptance_criteria_from_checkbox:
    message: "受け入れ条件はチェックボックスから抽出しました"
    action: "完了条件として適切か確認してください"
```

## 6. 説明文の整形

### 6.1 Markdown保持

issue本文のMarkdown形式をそのまま保持：

```yaml
description:
  overview: |
    ## 概要
    現在のシステムでは...
    
  purpose: |
    - 機能Aを追加
    - 性能を改善
```

### 6.2 不要要素の除去（オプション）

以下は除去を検討（設定可能）：

```yaml
remove_patterns:
  # 画像（サイズが大きくなるため）
  - pattern: "!\\[.*?\\]\\(.*?\\)"
    replace: "[画像]"
    
  # HTMLコメント
  - pattern: "<!--.*?-->"
    replace: ""
    
  # セクションヘッダー（既に構造化されているため）
  - pattern: "^#{2,}\\s+.*$"
    replace: ""
```

### 6.3 最大長制限

```yaml
max_description_length: 10000  # 文字数上限
truncation_message: "\n\n（以下省略 - 詳細はissueを参照）"
```

## 7. チケットIDの形式

### 7.1 基本形式

```yaml
# Issue番号をそのまま使用
ticket_id: "123"

# プレフィックス付き（オプション）
ticket_id: "GH-123"  # GitHub Issue
ticket_id: "PROJ-123"  # プロジェクトコード付き
```

### 7.2 カスタムフォーマット

```yaml
# 設定可能なフォーマット
ticket_id_format: "{prefix}-{issue_number}"

# プレフィックスの決定
prefix_rules:
  - from_label: "^project:(.+)$"  # ラベルから抽出
  - from_repo: true               # リポジトリ名を使用
  - default: "GH"                 # デフォルト値
```

## 8. 抽出精度の向上

### 8.1 コンテキスト考慮

```yaml
# リポジトリリンクの周辺コンテキストを分析
context_analysis:
  # コードブロック内のパスは除外
  ignore_in_code_blocks: true
  
  # 引用内は参照扱い
  treat_quotes_as_reference: true
  
  # リスト項目は関連リポジトリ候補
  list_items_are_related: true
```

### 8.2 重複除去

```yaml
# 同一リポジトリの重複を除去
deduplication:
  case_insensitive: true
  normalize_url: true  # .git 除去、末尾スラッシュ統一
```

## 9. 抽出結果の確信度

抽出した情報に確信度を付与：

```yaml
confidence_levels:
  high:    # 明示的なセクションヘッダーによる検出
    threshold: 0.9
    markers: ["## 概要", "## 目的", "## 受け入れ条件"]
    
  medium:  # キーワード推測による検出
    threshold: 0.6
    markers: ["関連", "参照", "フォールバック使用"]
    
  low:     # 単純なパターンマッチ
    threshold: 0.3
    markers: []

# 低確信度の情報には警告を付与
warning_on_low_confidence: true
```

## 10. 使用例

### 入力: Issue本文（構造化されている場合）

```markdown
## 概要
ユーザー認証機能を改善します。

## 目的
- セキュリティの向上
- ユーザー体験の改善

## 背景
現在の認証システムでは以下の課題がある:
- 二要素認証が未対応
- セッションタイムアウトが固定

## 要件
### 機能要件
- 二要素認証の導入
- セッション管理の改善

### 非機能要件
- 認証レスポンス: 500ms以内
- 可用性: 99.9%

## 受け入れ条件
- [ ] 二要素認証が有効化できること
- [ ] 既存ユーザーの認証が維持されること

## 修正対象
- org/backend-api

## 関連リポジトリ
- org/auth-library（認証ライブラリ）

## 参考
https://github.com/org/security-guidelines のガイドラインに従う
```

### 出力: 抽出結果（階層化フォーマット）

```yaml
extracted:
  ticket_id: "123"
  task_name: "ユーザー認証機能の改善"
  
  description:
    overview: |
      ユーザー認証機能を改善します。
    
    purpose: |
      - セキュリティの向上
      - ユーザー体験の改善
    
    background: |
      現在の認証システムでは以下の課題がある:
      - 二要素認証が未対応
      - セッションタイムアウトが固定
    
    requirements:
      functional:
        - "二要素認証の導入"
        - "セッション管理の改善"
      non_functional:
        - "認証レスポンス: 500ms以内"
        - "可用性: 99.9%"
    
    acceptance_criteria:
      - "二要素認証が有効化できること"
      - "既存ユーザーの認証が維持されること"
    
    scope: []  # 未検出
    out_of_scope: []  # 未検出
    
    notes: |
      https://github.com/org/security-guidelines のガイドラインに従う
  
  target_repositories:
    - name: "backend-api"
      url: "https://github.com/org/backend-api"
      confidence: 0.95
      
  related_repositories:
    - name: "auth-library"
      url: "https://github.com/org/auth-library"
      confidence: 0.85
    - name: "security-guidelines"
      url: "https://github.com/org/security-guidelines"
      confidence: 0.4
      
  extraction_report:
    sections_detected:
      - overview
      - purpose
      - background
      - requirements
      - acceptance_criteria
      - notes
    sections_missing:
      - scope
      - out_of_scope
    fallback_used: false
    warnings: []
```
