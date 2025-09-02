-- MacApp版のDavinci Resolveのスクリプトの配置場所
-- /Users/takashi/Library/Containers/com.blackmagic-design.DaVinciResolveLite/Data/Library/Application Support/Fusion/Scripts/

-- 【使い方】
-- 上記の所定のパスに本スクリプトを配置。
-- Davinci Resolveで書き出すジョブをすべて登録した後、
-- メニュー > ワークスペース > スクリプト から選択して実行。
-- 今開いているプロジェクトのジョブのみ書き出すので注意。
-- （複数のプロジェクトのジョブ一括書き出しには対応していない）

-- 【何が起こるか】
-- 開いているプロジェクトの全ジョブを書き出し終わった後、
-- 書き出されたファイルに対して何かしらの処理を実行することができる。
-- （今回はMacのショートカットappを呼び出す）
-- Youtube等に直接書き出すジョブの場合、
-- アップロードを待たずに処理を実行してしまう仕様。
-- （アップロード完了を監視するAPIが無いため）
-- ただし、複数の書き出し&アップロードのジョブがある場合、
-- 全ジョブの書き出し後に動くプログラムのため、
-- 最後のジョブ以外はアップロードが終わっていることになる。
-- （1:書出→1:UP→2:書出→2:UP→3:書出→本Lua、同時に3:UP の様な動き）
-- また、レンダー中はMacのcaffenateコマンドでスリープを防止している。

-- 設定（ログファイルを書き出す場所）
-- ユーザーのDownloadsディレクトリにした
-- ${HOME}はDavinci resolve側で別のパスに書き換えられているので使用不可
local realHome = "/Users/" .. os.getenv("USER")
local outputTxtPath = realHome .. "/Downloads/rendered_files.txt"
print("ログ書き出し先: " .. outputTxtPath)

-- スリープ防止 caffeinate 起動（Davinci Resolve用にscreenで起動）
os.execute("screen -dmS davinci_resolve_caffeinate -dimsu")
print("caffeinate をバックグラウンドで実行")

-- Resolve API 初期化
resolve = Resolve()
projectManager = resolve:GetProjectManager()
project = projectManager:GetCurrentProject()

-- レンダリング開始
project:StartRendering()

-- レンダリング終了待ち
while project:IsRenderingInProgress() do
    print("レンダリング中...")
    os.execute("sleep 1")
end

print("レンダリング完了")

-- 全レンダージョブの一覧取得
local jobList = project:GetRenderJobList()
local outputFilePaths = {}

for i, job in ipairs(jobList) do
    local dir = job["TargetDir"]
    local file = job["OutputFilename"]
    if dir and file then
        local fullPath = dir .. "/" .. file
        table.insert(outputFilePaths, fullPath)
        print("ジョブ " .. i .. ": " .. fullPath)
    end
end

-- ファイル書き出し
local f = io.open(outputTxtPath, "w")
if f then
    for _, path in ipairs(outputFilePaths) do
        f:write(path .. "\n")

        -- ここで書き出したファイルに実行したいことを記載
        -- （今回はあらかじめ作成してあったMacのショートカットappを呼ぶ）
        -- Notionアップロード用ショートカットapp実行
        local escapedPath = string.gsub(path, '"', '\\"')
        local command = 'shortcuts run "複数ファイルをNotionにアップロード" -i "' .. escapedPath .. '"'
        print("ショートカット実行: " .. command)
        os.execute(command)
    end
    f:close()
    print("✅ 出力ファイル一覧を書き出しました: " .. outputTxtPath)
else
    print("❌ ファイル書き出しに失敗しました")
end

-- caffeinate 終了
os.execute("screen -S davinci_resolve_caffeinate -X quit")
print("✅caffeinate をバックグラウンドで実行終了")

-- 全処理完了
print("\n✅全処理が完了しました\n\n")