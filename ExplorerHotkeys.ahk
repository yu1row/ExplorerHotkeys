; ============================================================
; ExplorerHotkeys.ahk
; Windows エクスプローラー向けのカスタムホットキー
;
; 要件: AutoHotkey v2.0
; 対象: エクスプローラーがアクティブなときのみ有効
;
; ホットキー:
;   Ctrl+Alt+N  選択中のフォルダを新しいタブで開く
;   Alt+M       ファイル一覧（メインビュー）にフォーカス
; ============================================================

#Requires AutoHotkey v2.0
#SingleInstance Force

; エクスプローラーがアクティブなときだけホットキーを有効化
#HotIf WinActive("ahk_exe explorer.exe")
^!n:: OpenSelectedInNewTab()      ; Ctrl+Alt+N : 選択フォルダを新しいタブで開く
!m:: FocusExplorerMainView()     ; Alt+M      : メインビューにフォーカス
#HotIf

; ============================================================
; メインビュー（ファイル一覧）にフォーカス
; ============================================================
FocusExplorerMainView() {
    hwnd := WinGetID("A")
    ; 方法1: UI Automation で「Items View / 項目ビュー」を直接探す
    if FocusMainViewViaUIA(hwnd)
        return
    ; 方法2: F6 でパネルを巡回しながら一覧に当たるまで進む
    FocusMainViewViaF6(hwnd)
}

; UIA でメインビュー要素を検索してフォーカスを当てる
FocusMainViewViaUIA(hwnd) {
    try {
        uia := ComObject("UIAutomationClient.CUIAutomation")
        root := uia.ElementFromHandle(hwnd)
        ; 名前で検索（英語UI / 日本語UI）
        for name in ["Items View", "項目ビュー"] {
            cond := uia.CreatePropertyCondition(30005, name)  ; UIA_NamePropertyId
            el := root.FindFirst(4, cond)                   ; TreeScope_Descendants
            if el {
                el.SetFocus()
                return true
            }
        }
        ; AutomationId で検索
        for id in ["ItemsView", "ItemView"] {
            cond := uia.CreatePropertyCondition(30011, id)  ; UIA_AutomationIdPropertyId
            el := root.FindFirst(4, cond)
            if el {
                el.SetFocus()
                return true
            }
        }
        ; コントロール種別が List のうち、ナビ以外の大きい一覧を探す
        cond := uia.CreatePropertyCondition(30003, 50008)  ; ControlType = List
        el := root.FindFirst(4, cond)
        if el {
            el.SetFocus()
            return true
        }
    }
    return false
}

; F6 でフォーカスを巡回し、メインビューに到達するまで繰り返す
FocusMainViewViaF6(hwnd) {
    try {
        uia := ComObject("UIAutomationClient.CUIAutomation")
        Loop 10 {
            focused := uia.GetFocusedElement()
            if IsMainFileList(focused)
                return true
            Send "{F6}"
            Sleep 60
        }
    } catch {
        ; UIA が使えない場合は F6 を数回送るだけ
        Loop 5
            Send "{F6}"
    }
    return false
}

; フォーカス先がメインビューのファイル一覧かどうかを判定
IsMainFileList(el) {
    try {
        name := el.CurrentName
        ct := el.CurrentControlType
        ; List かつ、ナビゲーション以外の一覧
        if ct != 50008  ; UIA_ListControlTypeId
            return false
        if InStr(name, "Navigation") || InStr(name, "ナビゲーション")
            return false
        if InStr(name, "View") || InStr(name, "ビュー") || InStr(name, "リスト")
            return true
        ; 名前が空でも List ならメインビューの可能性あり
        return true
    }
    return false
}

; ============================================================
; 選択中のフォルダを新しいタブで開く
; ============================================================
OpenSelectedInNewTab() {
    try {
        shell := ComObject("Shell.Application")
        for window in shell.Windows {
            try {
                items := window.Document.SelectedItems
                if items.Count = 0
                    continue
                item := items.Item(0)
                path := item.Path
                ; ファイルが選択されている場合は親フォルダのパスを取得
                if !DirExist(path)
                    path := RegExReplace(path, "\\[^\\]+$")
                ; Shell 動詞で新しいタブを開く（英語UI）
                try {
                    item.InvokeVerb("opennewtab")
                    return
                }
                ; Shell 動詞で新しいタブを開く（日本語UI）
                try {
                    item.InvokeVerb("新しいタブで開く")
                    return
                }
                ; 動詞が使えない場合はクリップボード経由でフォールバック
                OpenPathInNewTab(path)
                return
            }
        }
    } catch as err {
        MsgBox "エラー: " err.Message, "Explorer Hotkeys", "Icon!"
    }
    ToolTip "フォルダが選択されていません"
    SetTimer () => ToolTip(), -2000
}

; 新規タブ → アドレスバー → パス貼り付け → Enter で開くフォールバック
OpenPathInNewTab(path) {
    saved := ClipboardAll()
    A_Clipboard := path
    Send "^t"       ; 新しいタブ
    Sleep 80
    Send "^l"       ; アドレスバーにフォーカス
    Sleep 50
    Send "^v"       ; パスを貼り付け
    Sleep 50
    Send "{Enter}"
    Sleep 200
    try A_Clipboard := saved
}
