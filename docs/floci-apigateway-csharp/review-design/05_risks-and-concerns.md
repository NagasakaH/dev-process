# リスク・懸念事項

| No | 重大度 | カテゴリ | リスク/懸念事項 | 推奨対応 |
|----|--------|----------|-----------------|----------|
| 1 | 🔴 Critical | AC7/実 AWS 不使用 | AWS_ENDPOINT_URL 未設定時に AWS SDK / Terraform provider のデフォルトで実 AWS エンドポイントへ接続する可能性がある。AC7「floci のみで完結」を破る。 | Lambda 起動時・Terraform 実行時に AWS_ENDPOINT_URL（および var.endpoint）必須化。未設定なら fail-fast。 |
| 2 | 🔴 Critical | 設計矛盾（API/SFN 責務） | POST /todos が StartExecution 直後に id を返す設計と、ValidateTodo Lambda 側で id を生成する記述が共存し、E2E（POST→GET）の前提が崩れる。 | id 生成は api-handler に統一、ValidateTodo は受信 Todo の検証のみ。DTO/シーケンス/IT 期待値を全て同期。 |
| 3 | 🟠 Major | 要件カバレッジ | 「CRUD を中心」要件に対し POST/GET のみで Update/Delete/List の扱いと根拠が不足。 | サンプル API 範囲を POST/GET + 作成フロー検証に再定義し、Update/Delete/List をスコープ外明記または設計追加。 |
| 4 | 🟠 Major | README/AC6 | 設計時点で README 章構成・必須記載項目・検証方法が未定義（実装段階での担保のみ）。 | 必須セクションとレビュー観点を 05_test-plan.md と独立節で固定。 |
| 5 | 🟠 Major | ASL Retry 整合性 | PersistTodo の Retry 前提記述と ASL 定義例（Retry 節なし）の矛盾。 | ASL に Retry を明記、または Retry を将来拡張へ降格して全体を統一。 |
| 6 | 🟠 Major | Terraform provider | provider.tf の HCL（endpoints/skip_*/s3_use_path_style 等）が不足し、実 AWS 問い合わせ抑止証跡が弱い。 | aws ~> 6.0、必要 endpoints を var.endpoint に向ける完全 HCL 例を追加。 |
| 7 | 🟠 Major | GitLab CI | .gitlab-ci.yml の stages/jobs/image/services/variables/scripts/artifacts/after_script/DinD/tfstate 方針が未定義。 | E2E ジョブ内で floci 起動→package→apply→tests→destroy が完結する CI YAML スケルトンを設計に追加。 |
| 8 | 🟠 Major | docker-compose | image/ports/environment/FLOCI_HOSTNAME/volumes/healthcheck が未定義。 | floci 公式 image、4566 公開、FLOCI_HOSTNAME=floci、docker socket、healthcheck を含む YAML 例を追加。 |
| 9 | 🟠 Major | IAM 最小権限 | Lambda/SFN に必要な DynamoDB/StepFunctions/Lambda Invoke の最小権限ポリシーが未定義。 | aws_iam_role_policy / aws_iam_policy で Action/Resource を具体化。 |
| 10 | 🟠 Major | Lambda 設定 | role/memory_size/timeout/environment/source_code_hash が不足し、内部記述（timeout=30s）と Terraform 表が不整合。 | role、memory_size、timeout=30、必要環境変数、source_code_hash を Terraform 例に追加。 |
| 11 | 🟠 Major | API GW deployment | Method/Integration 変更時の再デプロイトリガーと create_before_destroy が未定義。 | aws_api_gateway_deployment.dev に triggers/depends_on/lifecycle create_before_destroy を明記。 |
| 12 | 🟡 Minor | CI 前提/Runner | GitLab Runner privileged 前提が未確定で AC5 実現性にリスク。 | privileged Docker executor を推奨前提と明記、不可時の shell executor + docker compose 代替手順を固定。 |
| 13 | 🟡 Minor | description 正規化 | description 空文字の扱いが未定義で UT/IT 期待値が分かれる。 | `string.IsNullOrWhiteSpace ? null : description.Trim()` を仕様化し UT を追加。 |
| 14 | 🟡 Minor | 補助スクリプト | scripts/deploy-local.sh / e2e.sh の内容が未定義。 | package→terraform init/apply→test→destroy の擬似コードを追加し CI と一致させる。 |
| 15 | 🟡 Minor | Integration fixture | DynamoDB テーブル準備方式が Terraform / AWS CLI 二択で未確定。 | xUnit fixture が AWSSDK CreateTableAsync を冪等実行する方式に固定。 |
| 16 | 🟡 Minor | invoke URL/FLOCI_HOSTNAME | var.endpoint と FLOCI_HOSTNAME の役割分担が不明瞭で、CI 上で localhost 混入を検出する観点が不足。 | 役割分担表を追加し、output invoke_url=var.endpoint、内部解決=FLOCI_HOSTNAME を明記。CI に localhost 混入検出 assertion を追加。 |

## 主要リスクの優先度

1. **DR-001（Critical）**: AC7 を直接破る。実装が進む前に必ず潰すべき最優先課題。
2. **DR-002（Critical）**: 設計の論理矛盾。API/SFN/IT/E2E の整合に直結し、実装着手不能。
3. **DR-006〜DR-011（Major）**: Terraform/IAM/Lambda/API GW/CI/compose の具体性不足。サンプル参照実装としての価値を毀損。
