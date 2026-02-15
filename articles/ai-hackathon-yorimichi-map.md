---
title: "yorimichi-map"
emoji: "🚗"
type: "idea"
topics: [gch4]
published: false
---

## 1. プロジェクト概要

### 対象ユーザー

**「ドライブは好きだけど、寄り道スポット探しが面倒」と感じるすべてのドライバー**

週末のドライブや旅行で「せっかくだから途中でどこか寄りたい」と思ったとき、複数のアプリを行き来しながらスポットを調べ、カーナビに手入力する——そんな煩わしさを感じたことはありませんか。寄り道マップは、その体験を根本から変えるために生まれました。

### 解決する課題

私たちが着目したのは、ドライブ計画における **3つのペインポイント** です。

**1. 検索疲れ**
ランチスポットや観光地を探すとき、食べログ、Instagram、Google マップ……と複数のアプリを横断して調べる必要があります。情報が分散しているため、比較検討だけで疲弊してしまいます。

**2. 機械的なルート提案**
従来のカーナビやルート検索は「最短」「最速」が基本です。「海沿いの道を走りたい」「雰囲気の良いカフェに立ち寄りたい」といった、人間の感覚的な要望に応えてくれるものではありませんでした。

**3. 転記の手間**
せっかく良いスポットを見つけても、そこからカーナビに住所を手入力する作業が待っています。経由地が複数あればなおさらです。出発前の貴重な時間が、データの転記作業に消えていきます。

### ソリューションの特徴

寄り道マップは、これらの課題を **AI とGoogle Maps の連携** によって一気に解決します。

- **自然言語でプランニング** — 「途中で美味しいお蕎麦屋さんに寄りたい」と話しかけるだけ。フォーム入力は不要です
- **インテリジェントな経由地提案** — AI がルート沿いの高評価スポットを検索し、3つの候補を提示。ユーザーが気に入ったものを選ぶだけでルートが確定します
- **リアルタイム交通情報** — 渋滞を考慮した所要時間と、高速道路の通行料金をリアルタイムで算出します
- **ワンタップでナビ開始** — ルートが決まったら、ボタン1つで Google マップアプリが起動。経由地を含むルートが自動設定された状態で、すぐにナビゲーションを開始できます
- **帰路の自動生成** — 「帰りのルートを作成」ボタンで、経由地を逆順にした帰り道を自動計算。往復のドライブ計画がシームレスに完結します

## 2. システムアーキテクチャ

![アーキテクチャ図](/images/ai-hackathon-yorimichi-map/architecture.png)

## 3. デモ動画

後ほど追記

## 4. 技術的なこだわりポイント

### 4.1 Gemini Automatic Function Calling — AI が「自分で判断して」API を叩く

寄り道マップの最大の技術的特徴は、**Vertex AI Gemini 2.5 Pro の Automatic Function Calling** を活用している点です。

従来の AI チャットボットでは、ユーザーの意図を解析してから開発者がルールベースで API を呼び分ける必要がありました。しかし本アプリでは、Gemini に2つの関数を「ツール」として登録するだけで、**AI 自身がどのタイミングでどの API を呼ぶべきかを判断し、自動実行** します。

```python
# Gemini に登録する2つのツール
_search_places_func = FunctionDeclaration(
    name="search_places",
    description="指定した場所の周辺でスポットを検索します。",
    parameters={...},
)

_calculate_route_func = FunctionDeclaration(
    name="calculate_route",
    description="出発地から目的地までのドライブルートを計算します。",
    parameters={...},
)
```

たとえばユーザーが「温泉に入ってから美術館にも寄りたい」と入力すると、Gemini は以下のように動作します。

1. `search_places(location_query='ルート周辺', place_type='温泉')` を自動実行
2. `search_places(location_query='ルート周辺', place_type='美術館')` を自動実行
3. 結果を分析し、おすすめのスポットを提案
4. ユーザーが「そこに寄ろう」と決めたら `calculate_route()` を自動実行してルート確定

この一連の流れが **すべて AI の判断で自動的に行われる** のがポイントです。開発者は「どの関数が使えるか」を定義するだけで、呼び出しのタイミングやパラメータの決定は Gemini に委ねています。

```python
# AutomaticFunctionCallingResponder が関数の自動実行を制御
afc_responder = AutomaticFunctionCallingResponder(
    max_automatic_function_calls=5,  # 暴走防止のため上限を設定
)
chat = model.start_chat(history=contents, responder=afc_responder)
response = chat.send_message(user_message)
```

### 4.2 Google Maps ディープリンク — プランニングからナビ開始まで5秒

ルートを計算して終わりではありません。**実際にナビゲーションを開始するまでがユーザー体験** です。

従来の方法では、調べた経由地を Google マップに1つずつ手入力する必要がありました。経由地が3箇所あれば、2〜3分はかかります。寄り道マップでは、ルート確定時に **ディープリンク URL** を自動生成し、ワンタップで Google マップアプリを起動します。

```python
def generate_google_maps_url(origin, destination, waypoints=None):
    params = {
        "api": "1",
        "origin": origin,
        "destination": destination,
        "travelmode": "driving",
    }
    if waypoints:
        params["waypoints"] = "|".join(waypoints)
    return f"https://www.google.com/maps/dir/?{urlencode(params)}"
```

生成される URL の例:

```
https://www.google.com/maps/dir/?api=1&origin=東京駅&destination=箱根湯本駅&waypoints=手打ち蕎麦 山路&travelmode=driving
```

この URL をスマートフォンでタップすると、Google マップアプリが起動し、出発地・経由地・目的地がすべて設定済みの状態でナビゲーションを開始できます。**手入力ゼロ、所要時間わずか5秒** です。

### 4.3 AI による経由地提案フロー — 「選ぶ楽しさ」を残す設計

AI に全自動で経由地を決められてしまうと、ドライブの楽しさが半減してしまいます。そこで寄り道マップでは、**AI が3つの候補を提示し、ユーザーが自分で選ぶ** というフローを採用しました。

```
ユーザー: 「途中で評価の高いお蕎麦屋さんに寄りたい」
    ↓
AI: 3つの候補を提案（名前・説明・住所付き）
    ↓
ユーザー: 気に入った候補をタップして選択
    ↓
「検索」ボタンで選択した経由地を含むルートを計算
    ↓
地図にルートが表示 → ワンタップでナビ開始
```

さらに、**帰路の自動生成** 機能も実装しています。帰りのルートを作成する際は、出発地と目的地を入れ替え、経由地の順序を逆転させて Routes API で再計算します。往復のドライブ計画が、追加の操作なしで完結します。

```python
# 帰路生成: origin ⇔ destination を入れ替え、waypoints を逆順に
origin = request.validated_data["destination"]
destination = request.validated_data["origin"]
waypoints = list(reversed(request.validated_data["waypoints"]))
route_data = calculate_route(origin, destination, waypoints)
```

## 5. 使用技術

### フロントエンド

| 技術 | バージョン | 用途 |
|------|-----------|------|
| React | 19 | UI フレームワーク |
| TypeScript | 5.9 | 型安全な開発 |
| Vite (rolldown-vite) | 7.2 | Rust ベースの高速バンドラ |
| React Compiler | 1.0 | 自動メモ化（useMemo/useCallback 不要） |
| TanStack Query | 5 | データフェッチ・キャッシュ管理 |
| Leaflet + react-leaflet | 1.9 / 5.0 | インタラクティブ地図 |
| Tailwind CSS | 4 | ユーティリティファースト CSS |
| oxlint | - | 型情報を活用した高速 Linter |
| Vitest | 4 | テストフレームワーク |

### バックエンド

| 技術 | バージョン | 用途 |
|------|-----------|------|
| Python | 3.13 | ランタイム |
| Django | 6 | Web フレームワーク |
| Django REST Framework | 3.16 | REST API 構築 |
| drf-spectacular | 0.29 | OpenAPI / Swagger ドキュメント自動生成 |
| Vertex AI SDK | - | Gemini 2.5 Pro との連携 |
| Google Maps Routes API v2 | - | ルート計算・交通情報・料金算出 |
| Google Maps Places API (New) | - | スポット検索・評価情報取得 |
| gunicorn | 23 | WSGI サーバー |
| uv | - | 高速パッケージマネージャー |

### インフラ

| 技術 | 用途 |
|------|------|
| Google Cloud Run | フロントエンド・バックエンドのコンテナ実行 |
| Artifact Registry | Docker イメージの管理 |
| Secret Manager | API キーの安全な管理 |
| Vertex AI | Gemini モデルのホスティング |
| Workload Identity Federation | GitHub Actions からの OIDC 認証 |
| Cloud Monitoring & Alerting | 監視・アラート |
| OpenTofu (Terraform) | Infrastructure as Code |
| Cloudflare | DNS 管理・カスタムドメイン |

### 開発環境

| 技術 | 用途 |
|------|------|
| Nix Flakes | 各コンポーネントごとの再現可能な開発環境 |
| direnv | ディレクトリ移動で自動的に環境をロード |
| treefmt | 全ファイルタイプの統一フォーマッタ |
| GitHub Actions | CI/CD（変更検知 → コンポーネント単位で実行） |
| pre-commit hooks | コミット時の自動チェック（ruff, oxlint, statix 等） |

## 6. 工夫した点・苦労した点

### Gemini API のレート制限対策

Vertex AI の Gemini API はリクエストが集中すると `429 ResourceExhausted` エラーを返します。ハッカソンのデモ中にこれが発生すると致命的なため、**指数バックオフ付きリトライ**（1秒 → 2秒 → 4秒）を実装しました。3回リトライしても解消しない場合は、ユーザーにわかりやすいエラーメッセージを返します。

### Function Calling の暴走防止

Automatic Function Calling は強力ですが、AI が無限にツールを呼び続ける可能性もあります。これを防ぐため、1リクエストあたりの **Function Call 上限を5回** に設定しています。また、会話履歴が長くなるとトークン消費が増大するため、**直近10メッセージのみ**を Gemini に送信するよう制御しています。

### リアルタイム交通情報の活用

Routes API への問い合わせ時、**出発時刻を「現在時刻＋5分後」** に設定しています。これにより、実際に出発するタイミングに近い交通状況を反映したルートが計算されます。5分後としているのは、ルート確認からナビ開始までの操作時間を考慮したものです。

### ディープリンクのセキュリティ

ユーザー入力の地名をそのまま URL に埋め込むと、パイプ文字 (`|`) による経由地の誤分割や、異常に長い文字列によるURL の破損が起こりえます。これを防ぐため、地名のサニタイズ処理（パイプ文字の除去、200文字以内の長さ制限）を実装しています。

## リポジトリ

https://github.com/gawakawa/yorimichi-map
