# ExplorerHotkeys

Windows エクスプローラー向けのカスタムホットキーを提供する [AutoHotkey v2](https://www.autohotkey.com/) スクリプトです。タブ操作やフォーカス移動をキーボードだけで行えるようにします。

## ホットキー

フォルダウィンドウ（`CabinetWClass`）がアクティブなときのみ有効です。コントロールパネルなど、別種類のエクスプローラーウィンドウでは動作しません。

| ホットキー | 動作 |
|-----------|------|
| `Ctrl` + `Shift` + `T` | 選択中のフォルダを新しいタブで開く |
| `Alt` + `F` | ファイル一覧（メインビュー）にフォーカス |

### Ctrl+Shift+T の動作

1. アクティブなタブから選択中のアイテムのパスを取得します。
2. ファイルが選択されている場合は、その親フォルダのパスを使います。
3. 新しいタブを開き、COM の `Navigate2` でパスへ移動します（通常はアドレスバーを経由しません）。
4. 移動後、ファイル一覧（メインビュー）にフォーカスを戻します。

`Navigate2` が失敗した場合は、フォールバックとして `Ctrl+T` → `Ctrl+L` → パス入力 → `Enter` で開き、その後メインビューにフォーカスを戻します。

| 状況 | 通知 |
|------|------|
| 何も選択されていない | ツールチップ「フォルダが選択されていません」 |
| エクスプローラーを特定できない | ツールチップ「エクスプローラーを特定できません」 |
| その他のエラー | ダイアログでエラー内容を表示 |

### Alt+F の動作

ファイル一覧（メインビュー）へフォーカスを移します。

1. **ControlFocus** — `DirectUIHWND2` コントロールへフォーカス
2. **F2 → Esc** — 項目が選択されている場合、名前変更をキャンセルして一覧へフォーカスを戻す

`Alt+F` はエクスプローラーの「ファイル」メニューと競合するため、スクリプト側で `$` プレフィックスと `Alt` キー解除を行っています。

## 要件

- Windows 10 / 11
- [AutoHotkey v2.0](https://www.autohotkey.com/) 以降
- `Ctrl+Shift+T` はタブ対応エクスプローラーが必要（Windows 11 標準のエクスプローラーなど）
- `Alt+F` はタブ非対応のエクスプローラーでも利用可能

## インストール

1. [AutoHotkey v2](https://www.autohotkey.com/) をインストールします。
2. このリポジトリをクローンするか、`ExplorerHotkeys.ahk` をダウンロードします。

   ```bash
   git clone https://github.com/yu1row/ExplorerHotkeys.git
   ```

3. `ExplorerHotkeys.ahk` をダブルクリックして実行します。

### 起動時に自動実行する（任意）

1. `Win` + `R` で「ファイル名を指定して実行」を開き、`shell:startup` と入力して Enter
2. 開いたフォルダに `ExplorerHotkeys.ahk` のショートカットを作成する

## 使い方

1. スクリプトを起動した状態でエクスプローラーを開きます。
2. フォルダ（またはファイル）を選択して `Ctrl` + `Shift` + `T` を押すと、新しいタブでそのフォルダが開きます。
3. サイドバーやアドレスバーにフォーカスがあるとき、`Alt` + `F` でファイル一覧に戻れます。

スクリプトを編集した場合は、タスクトレイの AutoHotkey アイコンから **Reload** して変更を反映してください。

## ファイル構成

```
ExplorerHotkeys/
├── ExplorerHotkeys.ahk   # メインスクリプト
├── LICENSE               # MIT License
└── README.md
```

## カスタマイズ

ホットキーは `ExplorerHotkeys.ahk` 先頭付近で変更できます。`$` プレフィックスはエクスプローラーの標準ショートカットを横取りするために必要です。

```ahk
$^+t:: OpenSelectedInNewTab()      ; Ctrl+Shift+T
$!f:: {                           ; Alt+F
    Send "{Alt up}"
    FocusExplorerMainView()
}
```

### 環境によって動作が異なる場合

- **Alt+F でメインビューにフォーカスできない** — `FocusExplorerMainView()` 内の `DirectUIHWND2` を `DirectUIHWND3` などに変更してみてください（Windows バージョンにより異なります）。
- **Ctrl+Shift+T でフォルダが開かない** — `NavigateActiveExplorerToPath()` のフォールバック処理（`Send "^l"` など）を環境に合わせて調整してください。`Ctrl+L` が効かない場合は `Send "!d"` や `Send "{F4}"` を試してください。
- **ホットキーが反応しない** — フォルダウィンドウがアクティブか確認し、スクリプトが起動中か・Reload 済みかを確認してください。

AutoHotkey のホットキー記法については [公式ドキュメント](https://www.autohotkey.com/docs/v2/Hotkeys.htm) を参照してください。

## ライセンス

[MIT License](LICENSE) — Copyright (c) 2026 [yu1row](https://github.com/yu1row)
