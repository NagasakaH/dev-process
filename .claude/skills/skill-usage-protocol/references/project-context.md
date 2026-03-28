# Project Context（ワークフロー利用時の詳細）

## project.yaml について

`project.yaml` はワークフローの進捗管理ファイルです。
project.yaml の読み書きは `project-state` スキルが担当し、その利用手順を `prompts/workflow/*.md` が定義します。
各汎用スキル自体は project.yaml に依存しません。

**ワークフロー利用時の流れ**:
1. `prompts/workflow/{step}.md` からコンテキスト取得手順を確認
2. `project-state` スキルで project.yaml から必要情報を抽出
3. 汎用スキルを実行（入力はコンテキストとして渡す）
4. `project-state` スキルで結果を project.yaml に書き戻し

## setup.yaml

`setup.yaml` はプロジェクトの初期入力ファイルです（チケット情報、要件など）。
