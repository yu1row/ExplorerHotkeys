; ============================================================
; ExplorerHotkeys.ahk
; Windows エクスプローラー向けのカスタムホットキー
;
; 作者: yu1row
; ライセンス: MIT License
;
; 要件: AutoHotkey v2.0
; 対象: エクスプローラー（CabinetWClass）がアクティブなときのみ有効
;
; ホットキー:
;   Ctrl+Shift+T  選択中のフォルダを新しいタブで開く
;   Alt+F         ファイル一覧（メインビュー）にフォーカス
; ============================================================

#Requires AutoHotkey v2.0
#SingleInstance Force

; エクスプローラーがアクティブなときだけホットキーを有効化
; CabinetWClass = 通常のフォルダウィンドウ
#HotIf WinActive("ahk_class CabinetWClass")
$^+t:: OpenSelectedInNewTab()      ; Ctrl+Shift+T : 選択フォルダを新しいタブで開く
$!f:: {                           ; Alt+F : メインビューにフォーカス（$ でメニュー加速キーを横取り）
    Send "{Alt up}"
    FocusExplorerMainView()
}
#HotIf

; ============================================================
; メインビュー（ファイル一覧）にフォーカス
; ============================================================
FocusExplorerMainView() {
    ; メインビュー（DirectUIHWND2）へフォーカス
    ; ※ Windows バージョンによっては DirectUIHWND3 等になる場合あり
    try ControlFocus "DirectUIHWND2", "A"

    ; 選択アイテムがある場合、F2（名前の変更）→ Esc で一覧へフォーカスを戻す
    try {
        if Explorer_GetSelected()
            Send "{F2}{Esc}"
    }
}

; アクティブなエクスプローラータブの Shell ウィンドウを取得
; shell.Windows は同一 HWND のタブを複数返すため、IShellBrowser でアクティブタブを特定する
GetActiveExplorerTab(hwnd) {
    activeTab := 0
    try activeTab := ControlGetHwnd("ShellTabWindowClass1", "ahk_id " hwnd)
    shell := ComObject("Shell.Application")
    static IID_IShellBrowser := "{000214E2-0000-0000-C000-000000000046}"
    fallback := ""
    for window in shell.Windows {
        try {
            if window.HWND != hwnd
                continue
            ; タブ非対応のエクスプローラー
            if !activeTab
                return window
            ; タブ対応: IShellBrowser::GetWindow でタブ HWND を取得し照合
            shellBrowser := ComObjQuery(window, IID_IShellBrowser, IID_IShellBrowser)
            tabHwnd := 0
            ComCall(3, shellBrowser, "uint*", &tabHwnd)
            if tabHwnd = activeTab
                return window
            fallback := window
        } catch {
            continue
        }
    }
    return fallback
}

; 選択中のアイテムが存在するかチェック
Explorer_GetSelected() {
    window := GetActiveExplorerTab(WinExist("A"))
    if !window
        return false
    try return window.Document.SelectedItems.Count > 0
    return false
}

; ============================================================
; 選択中のフォルダを新しいタブで開く
; ============================================================
OpenSelectedInNewTab() {
    hwnd := WinExist("A")
    window := GetActiveExplorerTab(hwnd)
    if !window {
        ToolTip "エクスプローラーを特定できません"
        SetTimer () => ToolTip(), -2000
        return
    }

    try {
        items := window.Document.SelectedItems
        if items.Count = 0 {
            ToolTip "フォルダが選択されていません"
            SetTimer () => ToolTip(), -2000
            return
        }
        targetDir := items.Item(0).Path
        ; ファイルが選択されている場合は親フォルダのパスを取得
        if !DirExist(targetDir)
            targetDir := RegExReplace(targetDir, "\\[^\\]+$")
    } catch as err {
        MsgBox "エラー: " err.Message, "Explorer Hotkeys", "Icon!"
        return
    }

    ; 新しいタブを開いてパスへ移動（アドレスバーを経由しない）
    if !NavigateActiveExplorerToPath(hwnd, targetDir) {
        ; フォールバック: アドレスバーからパスを入力
        Send "^t"
        Sleep 200
        Send "^l"
        Sleep 50
        SendInput "{Text}" targetDir
        Sleep 50
        Send "{Enter}"
        Sleep 300
    }
    FocusExplorerMainView()
}

; 新しいタブを開き Navigate2 で移動（アドレスバーを経由しない）
NavigateActiveExplorerToPath(hwnd, path) {
    try {
        prevTabHwnd := 0
        try prevTabHwnd := ControlGetHwnd("ShellTabWindowClass1", "ahk_id " hwnd)
        if prevTabHwnd
            PostMessage 0x111, 0xA21B, 0, prevTabHwnd  ; WM_COMMAND: 新しいタブ
        else
            Send "^t"
        Loop 40 {
            Sleep 50
            curTabHwnd := 0
            try curTabHwnd := ControlGetHwnd("ShellTabWindowClass1", "ahk_id " hwnd)
            ; タブ切り替え完了を待つ
            if prevTabHwnd && curTabHwnd = prevTabHwnd
                continue
            newTab := GetActiveExplorerTab(hwnd)
            if !newTab
                continue
            newTab.Navigate2(path)
            Sleep 200
            return true
        }
    } catch {
    }
    return false
}
