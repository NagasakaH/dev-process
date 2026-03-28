# ユーザー確認・バリデーション・コミット

## ユーザー確認ループ

生成した setup.yaml をユーザーに提示し、確認を求めます：

```markdown
setup.yaml を生成しました。内容を確認してください。

修正したい箇所があれば教えてください。
問題なければ「OK」と言ってください。
```

修正依頼があった場合は該当箇所を更新し、再度確認を求めます。

## バリデーション

確認完了後、スキーマバリデーションを実行：

```bash
# スキーマバリデーション
python3 -c "
import yaml
from jsonschema import validate
with open('setup.schema.yaml') as s:
    schema = yaml.safe_load(s)
with open('setup.yaml') as f:
    data = yaml.safe_load(f)
validate(data, schema)
print('✅ setup.yaml はスキーマに準拠しています')
"
```

## コミット

```bash
git add setup.yaml
git commit -m "docs: setup.yaml を作成

- タスク: {task_name}
- チケット: {ticket_id}
- 対象リポジトリ: {target_repositories}"
```
