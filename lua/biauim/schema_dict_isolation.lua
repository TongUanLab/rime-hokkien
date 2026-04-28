local function init(env)
    local config = env.engine.schema.config
    env.tag_map = {} -- 使用 Table 作為集合，查詢效率為 O(1)

    local list = config:get_list("customization/region_tags")
    if list then
        local size = list.size or 0

        for i = 0, size - 1 do
            local val = list:get_value_at(i)
            if val then
                -- 再通過 get_string() 轉為 Lua 字串
                local tag = val:get_string()
                if tag then
                    env.tag_map[tag] = true
                end
            end
        end
    end
end

local function filter(translation, env)
    for cand in translation:iter() do
        local text = cand.text
        
        -- 簡單檢查是否含有標籤 (節省效能)
        if text:find("%[") then
            local is_allowed = false
            
            -- 遍歷所有標籤，只要有一個標籤符合設定檔中的 tag，就標記為保留
            for tag in text:gmatch("%[(.-)%]") do
                if env.tag_map[tag] then
                    is_allowed = true
                    break
                end
            end

            if is_allowed then
                -- 移除所有 [內容] 括號及其內容
                -- %b[] 代表匹配平衡的方括號
                -- local tags = text:match("%b[]") or ""
                local tags = text:match("%[.*%]") or ""
                local comment = cand.comment .. tags
                local clean_text = text:gsub("%[.*%]", "")
                
                -- Yield 去除標籤後的詞，並將原標籤內容附加到 comment 中
                new_cand = Candidate(cand.type, cand.start, cand._end, clean_text, comment)
                new_cand.preedit = cand.preedit
                yield( new_cand )
            else
                -- 如果 is_allowed 為 false (即標籤都不匹配)，則不 yield，達到過濾效果
                -- yield( Candidate(cand.type, cand.start, cand._end, "N/A", cand.comment) )
            end
        else
            -- 沒有標籤的詞，直接 Yield (預設保留)
            yield(cand)
        end
    end
end

return {
    init = init,
    func = filter
}