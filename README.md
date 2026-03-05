# beadot

**写真をアイロンビーズの図案に変換するアプリ**

[<img src="https://developer.apple.com/assets/elements/badges/download-on-the-app-store.svg" height="40">](https://apps.apple.com/jp/app/beadot-%E3%82%A2%E3%82%A4%E3%83%AD%E3%83%B3%E3%83%93%E3%83%BC%E3%82%BA%E5%9B%B3%E6%A1%88%E3%83%A1%E3%83%BC%E3%82%AB%E3%83%BC/id6759835185)

---

## 概要

写真を撮影・選択するだけで、パーラービーズ・ナノビーズ・ハマビーズに対応したアイロンビーズの図案を自動生成します。CIEDE2000色差式による高精度な色マッチングと、Floyd-Steinbergディザリングによる自然なグラデーション表現を実現。完全ローカル処理でプライバシーも安心。

## 主な機能

- **3ブランド対応** — パーラー（57色）/ ナノ（50色）/ ハマ（52色）
- **5種類のプレート形状** — 四角形 / 六角形 / 丸形 / ハート形 / 星形
- **3つの表示モード** — 色 / 記号 / 番号
- **買い物リスト** — 必要なビーズの色と個数を自動集計
- **実寸PDF出力** — 印刷してそのまま使える
- **多言語対応** — 日本語 / English / 中文

## 技術スタック

| カテゴリ | 技術 |
|---|---|
| フレームワーク | Flutter / Dart |
| 色変換 | CIEDE2000色差式（Sharma 2005論文準拠） |
| ディザリング | Floyd-Steinberg（Lab色空間） |
| リサイズ | Area補間（OpenCV INTER_AREA相当） |
| 前処理 | Gaussian平滑化 + ヒストグラムストレッチ + 彩度補正 |
| DB | SQLite（sqflite） |
| PDF | dart pdf パッケージ |
| 課金 | In-App Purchase 直接実装 |

## アーキテクチャ

```
lib/
├── main.dart / app.dart          # エントリポイント・アプリ設定
├── constants.dart                # 定数定義
├── models/                       # データモデル（7ファイル）
│   ├── bead_brand.dart           #   ビーズブランド定義
│   ├── bead_color.dart           #   色データ（RGB/Lab/メタ情報）
│   ├── plate_shape.dart          #   プレート形状
│   ├── plate_size.dart           #   プレートサイズ
│   ├── conversion_settings.dart  #   変換設定
│   ├── pattern_data.dart         #   図案データ
│   └── shopping_item.dart        #   買い物リスト項目
├── screens/                      # 画面（10ファイル）
│   ├── camera_screen.dart        #   カメラ撮影
│   ├── settings_select_screen.dart #  変換設定選択
│   ├── crop_screen.dart          #   トリミング（形状マスク付き）
│   ├── converting_screen.dart    #   変換処理（プログレス表示）
│   ├── pattern_screen.dart       #   図案表示・操作
│   ├── preview_screen.dart       #   完成プレビュー
│   ├── shopping_list_screen.dart #   買い物リスト
│   ├── gallery_screen.dart       #   保存図案一覧
│   ├── app_settings_screen.dart  #   アプリ設定
│   └── premium_screen.dart       #   プレミアム購入
├── widgets/                      # 共通ウィジェット（5ファイル）
│   ├── bead_grid_painter.dart    #   正方形グリッド描画
│   ├── hex_grid_painter.dart     #   六角形グリッド描画
│   ├── color_palette_bar.dart    #   色パレットバー
│   ├── plate_shape_selector.dart #   形状セレクタ
│   └── segment_control.dart      #   セグメントコントロール
├── services/                     # サービス層（6ファイル）
│   ├── conversion_service.dart   #   変換パイプライン（Isolate並列）
│   ├── database_service.dart     #   SQLite操作
│   ├── preference_service.dart   #   設定管理
│   ├── purchase_service.dart     #   IAP管理
│   ├── pdf_service.dart          #   PDF生成
│   └── color_service.dart        #   色ユーティリティ
├── utils/                        # アルゴリズム（7ファイル）
│   ├── ciede2000.dart            #   CIEDE2000色差計算
│   ├── color_converter.dart      #   RGB↔Lab変換
│   ├── dithering.dart            #   Floyd-Steinbergディザリング
│   ├── image_resizer.dart        #   Area補間リサイズ
│   ├── preprocessing.dart        #   画像前処理パイプライン
│   ├── isolated_pixel_remover.dart #  孤立ピクセル除去
│   └── mask_generator.dart       #   形状マスク生成
├── data/
│   └── bead_data_loader.dart     #   色データ読み込み
└── l10n/
    └── app_localizations.dart    #   3言語ローカライゼーション
```

## 色変換パイプライン

```
入力画像
  → Area補間リサイズ（プレートサイズに縮小）
  → 前処理（Gaussian σ=0.5 → ヒストグラムストレッチ → 彩度×1.1）
  → 形状マスク適用（円/ハート/星のパラメトリック生成）
  → CIEDE2000最近色マッチング（パレット制限付き）
  → Floyd-Steinbergディザリング（Lab空間、強度0-100%）
  → 孤立ピクセル除去（8近傍）
  → 図案データ出力
```

## ライセンス

All rights reserved. このコードはポートフォリオ目的で公開しています。

## 開発者

[mamonis.studio](https://mamonis.studio)
