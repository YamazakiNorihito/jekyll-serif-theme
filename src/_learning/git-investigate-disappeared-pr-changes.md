---
title: "マージ済みPRの変更が消えた時の調査方法"
date: 2026-03-04
weight: 7
tags:
  - Git
  - GitHub
  - トラブルシューティング
description: "PRでマージした変更がいつの間にかmainから消えていた場合に、どのPRで消えたかを特定する手順"
---

あるPRでマージした変更が、いつの間にかmainブランチから消えていた。そんな時にどこで消えたのかを特定する調査方法をまとめる。

## 前提

- mainブランチを親として子ブランチを作成し、修正が終わったらGitHubのPRでマージする運用
- PR `#739` でマージした内容がいつの間にかmainから消えていた
- 消えたのは特定ファイル（`path/to/target-file.ts`）に対する変更
- 気づいた時点で複数のマージが行われており、どこで消えたか分からない

**ゴール**: どのPRで変更が消えたのか特定し、影響範囲を把握する

## 調査の全体像

1. 消えたPRがmainに存在するか確認する
2. 消えたPRの変更内容を把握する
3. そのファイルを後から変更したコミットを一覧表示する
4. 各コミットがどのPRに属するか特定する
5. 各PRの最新コミットの差分を古いPRから順に確認し、消失箇所を特定する

## Step 1. 消えたPRのマージコミットがmainにあるか確認する

マージコミットが見つかれば、一度はmainに入っていたことが確定する。
見つからなければそもそもマージされていない可能性がある。

```bash
$ git log --merges --oneline main | rg "#739"
#-> 0ec758fa Merge pull request #739 from ******

# mainにまだマージされていないブランチ（例えばdevelopにだけマージ済み）のPRを探す場合は --all
$ git log --merges --oneline --all | rg "#739"
```

## Step 2. 消えたPRの変更内容を把握する

後のStepで「消えたかどうか」を判定するために、先にPR #739がどんな変更を入れたか把握しておく。
`^1`はマージ先（main）、`^2`はマージ元（PRブランチ）なので、この差分がPRの変更内容そのもの。

```bash
# 特定ファイルの変更だけ見る
git diff 0ec758fa^1 0ec758fa^2 -- path/to/target-file.ts

# PR全体の変更を見る場合は -- path を省略
git diff 0ec758fa^1 0ec758fa^2
```

この差分で追加された関数名・変数名・ロジックを把握しておく。後のStepで「消えたかどうか」の判定基準になる。

## Step 3. 対象ファイルの変更履歴を一覧表示する

PR #739のマージ以降に、同じファイルを変更したコミットを全て洗い出す。
この中に「PR #739の変更を上書きした犯人」がいる。

`0ec758fa..main` は「PR #739のマージ後からmainの先頭まで」という範囲指定。

```bash
$ git log --oneline 0ec758fa..main -- path/to/target-file.ts
c74d9778 Revert "add helper method"
39b338cc chore: clean up unused variables
11ed4a2e refactor: extract magic numbers to constants
db6ced8c feat: rename calcTotal to calculateOrderTotal
5ad3db55 style: apply camelCase naming convention
9d0dee7e feat: add auto-config on user signup
177927b7 Merge branch 'develop' into task/ITEM-480
fc6bc1ba Merge pull request #725 from myteam/task/ITEM-480
aa9151ab fix: add null check before toggling flag
53f13e99 refactor: rename getUserData to fetchUserProfile
8f4071b0 fix: correct WHERE clause and update error text
5f3fc445 feat: validate email format on account activation
f739a7ff chore: update import paths after directory move
424a6bbb Merge remote-tracking branch 'origin/develop' into task/ITEM-480
```

上が新しく、下が古い。

## Step 4. 各コミットがどのPRに属するか特定する

Step 3で出た各コミットに対して、「このコミットはどのPRのマージによってmainに入ったか」を調べる。

```bash
git log --merges --ancestry-path <コミットhash>..main --oneline | rg "Merge pull request" | tail -1
```

- `--ancestry-path`: コミットからmainまでの直系経路だけを辿る
- `--merges`: マージコミットだけ表示
- `rg "Merge pull request"`: PRマージだけに絞る（ブランチマージを除外）
- `tail -1`: 最も古いPRマージ = そのコミットが最初に取り込まれたPR

### --ancestry-pathとは

通常の `A..B` はBまでの履歴全部 − Aまでの履歴全部 → 残り全部を表示する。
`--ancestry-path` をつけると、親を辿っていくとAにたどり着くコミットだけに絞る。

```text
  A --- B --- C --- M --- main
                   /
      X --- Y ---Z

  git log A..main → B, C, X, Y, Z, M
  git log --ancestry-path A..main → B, C, M
```

### Step 3の全コミットに対して実行する

```bash
git log --merges --ancestry-path 424a6bbb..main --oneline | rg "Merge pull request" | tail -1
#-> fc6bc1ba Merge pull request #725 from myteam/task/ITEM-480
git log --merges --ancestry-path f739a7ff..main --oneline | rg "Merge pull request" | tail -1
#-> fc6bc1ba Merge pull request #725 from myteam/task/ITEM-480
git log --merges --ancestry-path 5f3fc445..main --oneline | rg "Merge pull request" | tail -1
#-> db662c0f Merge pull request #736 from myteam/task/BUG-295
git log --merges --ancestry-path 8f4071b0..main --oneline | rg "Merge pull request" | tail -1
#-> db662c0f Merge pull request #736 from myteam/task/BUG-295
git log --merges --ancestry-path 53f13e99..main --oneline | rg "Merge pull request" | tail -1
#-> db662c0f Merge pull request #736 from myteam/task/BUG-295
git log --merges --ancestry-path aa9151ab..main --oneline | rg "Merge pull request" | tail -1
#-> c5fbed6d Merge pull request #742 from myteam/task/BUG-346
git log --merges --ancestry-path fc6bc1ba..main --oneline | rg "Merge pull request" | tail -1
#-> 88c37ea6 Merge pull request #751 from myteam/task/ITEM-530
git log --merges --ancestry-path 177927b7..main --oneline | rg "Merge pull request" | tail -1
#-> 88c37ea6 Merge pull request #751 from myteam/task/ITEM-530
git log --merges --ancestry-path 9d0dee7e..main --oneline | rg "Merge pull request" | tail -1
#-> cc098549 Merge pull request #735 from myteam/task/TICKET-259
git log --merges --ancestry-path 5ad3db55..main --oneline | rg "Merge pull request" | tail -1
#-> cc098549 Merge pull request #735 from myteam/task/TICKET-259
git log --merges --ancestry-path db6ced8c..main --oneline | rg "Merge pull request" | tail -1
#-> cc098549 Merge pull request #735 from myteam/task/TICKET-259
git log --merges --ancestry-path 11ed4a2e..main --oneline | rg "Merge pull request" | tail -1
#-> cc098549 Merge pull request #735 from myteam/task/TICKET-259
git log --merges --ancestry-path 39b338cc..main --oneline | rg "Merge pull request" | tail -1
#-> cc098549 Merge pull request #735 from myteam/task/TICKET-259
git log --merges --ancestry-path c74d9778..main --oneline | rg "Merge pull request" | tail -1
#-> cc098549 Merge pull request #735 from myteam/task/TICKET-259
```

結果を表にまとめる。

### 結果まとめ

| コミット                                                                   | 所属PR   |
| -------------------------------------------------------------------------- | -------- |
| `424a6bbb`, `f739a7ff`                                                     | PR #725  |
| `5f3fc445`, `8f4071b0`, `53f13e99`                                         | PR #736  |
| `aa9151ab`                                                                 | PR #742  |
| `fc6bc1ba`, `177927b7`                                                     | PR #751  |
| `9d0dee7e`, `5ad3db55`, `db6ced8c`, `11ed4a2e`, `39b338cc`, `c74d9778`     | PR #735  |

## Step 5. 各PRの最新コミットの差分を確認し、消失を特定する

各PRの中で一番新しい（最新の）コミットのhash idで差分を確認する。
それを古いPRから順にやっていく。

各PRの最新コミットを確認すれば、そのPRが最終的にファイルをどう変えたかが分かる。

```bash
# 1. PR #725 の最新コミット
git diff f739a7ff^ f739a7ff -- path/to/target-file.ts

# 2. PR #736 の最新コミット
git diff 53f13e99^ 53f13e99 -- path/to/target-file.ts

# 3. PR #742 の最新コミット
git diff aa9151ab^ aa9151ab -- path/to/target-file.ts

# 4. PR #751 の最新コミット
git diff 177927b7^ 177927b7 -- path/to/target-file.ts

# 5. PR #735 の最新コミット
git diff c74d9778^ c74d9778 -- path/to/target-file.ts
```

※`^`は git で「親コミット」を意味

### 消失の判定方法

差分の中に、Step 2で把握したPR #739の変更が **打ち消されている** ものがあれば、そのPRが犯人。

具体的には以下のパターンを探す：

```diff
- calcTotalWithTax        ← PR #739で追加された新しい関数が削除されている
+ calcTotal               ← 旧関数に戻っている
```

PR #739で追加されたコード（関数名・ロジック）が `-`（削除）になっていて、古いコード（PR #739以前のもの）が `+`（追加）になっていれば、そのPRで消失が起きている。

## Step 6. 原因PRのブランチ内コミットを確認する

Step 5 で PR `#735`（マージコミット: `cc098549`）が犯人と判明したとする。
次に、そのPRのブランチにどんなコミットがあったかを確認し、なぜ変更が消えたのか原因を探る。

コンフリクト解消時に誤って古い方を採用した、rebase時に変更が落ちた、などのパターンが多い。

### PRブランチ固有のコミット一覧を出す

`^2` はマージ元（PRブランチ）、`^1` はマージ先（main）。
`cc098549^2 --not cc098549^1` で「PRブランチにだけ存在するコミット」を取得できる。

```bash
git log --format="%H %ai %ci %s" cc098549^2 --not cc098549^1
```

出力例:

```text
a1b2c3d4... 2025-07-09 09:47:49 +0900 2025-07-09 10:05:45 +0900 fix: improve error handling
b2c3d4e5... 2025-07-07 07:26:40 +0900 2025-07-07 07:26:40 +0900 feat: add login theme config
c3d4e5f6... 2025-06-19 14:42:13 +0900 2025-07-03 09:35:50 +0900 Revert change
d4e5f6a7... 2025-06-04 08:42:22 +0900 2025-07-03 09:35:50 +0900 refactor: clean up variables
e5f6a7b8... 2025-04-18 13:46:01 +0900 2025-07-03 09:35:50 +0900 feat: automate settings on registration
```

### `--format` プレースホルダ

| プレースホルダ | 意味                                                    |
| -------------- | ------------------------------------------------------- |
| `%H`           | コミットのフルハッシュ (40文字)                          |
| `%ai`          | Author Date (ISO 8601風: `2025-03-15 10:30:00 +0900`)  |
| `%ci`          | Commit Date (ISO 8601風: 同上の形式)                    |
| `%s`           | コミットメッセージの1行目 (subject)                      |

### Author Date vs Commit Date

- **Author Date (`%ai`)** — そのコミットが最初に作成された日時
- **Commit Date (`%ci`)** — コミットオブジェクトが最後に変更された日時

通常は同じ値になるが、rebase すると異なる値になる。

Git は「Author（書いた人）」と「Committer（適用した人）」を別概念として扱っている。rebase は「既存のパッチを別のベースに再適用する」操作なので:

- **Author Date** → 元のコードを書いた日時 → 変える理由がない → **保持**
- **Commit Date** → コミットオブジェクトを作った日時 → 再適用した → **更新**

```text
元のコミット (hash: aaa111)
  AuthorDate:    2025-04-18  ← 書いた日
  CommitterDate: 2025-04-18  ← 作った日

    ↓ rebase

新しいコミット (hash: bbb222)  ← ハッシュは変わる
  AuthorDate:    2025-04-18  ← 元のままコピー
  CommitterDate: 2025-07-03  ← rebase実行日に更新
```

上の出力例で `%ai` と `%ci` の値が異なるコミットがあれば、そのコミットは rebase されている。rebase 時のコンフリクト解消で変更が消えた可能性がある。

## Step 7. 原因PRで変更になったファイルの一覧を表示する

```bash
git diff --name-only cc098549^1 cc098549^2
```

## Step 8. 他にも消えた変更がないか確認する

Step 7で原因PR（#735）の変更ファイル一覧が分かった。
この中に、消えたPR（#739）以外にも被害を受けたファイルがあるかもしれない。

### 被害候補のファイルを絞り込む

原因PR（#735）と消えたPR（#739）の変更ファイルを比較して、両方が変更しているファイルを探す。

```bash
# 原因PR（#735）の変更ファイル
git diff --name-only cc098549^1 cc098549^2

# 消えたPR（#739）の変更ファイル
git diff --name-only 0ec758fa^1 0ec758fa^2
```

両方に共通するファイルが「消失の可能性があるファイル」。

ただし、#739以外のPRも被害を受けている可能性がある。
それを調べるには、Step 7の各ファイルに対してStep 3〜5を繰り返す。

### 各ファイルに対してStep 3〜5を実行する

```bash
# Step 3: そのファイルの変更履歴を出す
git log --oneline <原因PRのマージコミット>..main -- <Step 7のファイル>

# Step 4: 各コミットの所属PRを特定
git log --merges --ancestry-path <コミット>..main --oneline | rg "Merge pull request" | tail -1

# Step 5: 差分で消失を確認
git diff <コミット>^ <コミット> -- <ファイル>
```

これを Step 7 で出た全ファイルに対して行えば、PR #739以外にも消えた変更があるかどうかが分かる。
