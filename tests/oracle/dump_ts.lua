-- Dump tree-sitter highlight captures per file, for the oracle comparison.
--
--   nvim -u NONE --headless -l tests/oracle/dump_ts.lua MANIFEST OUTDIR
--
-- MANIFEST: lines of `TSLANG<TAB>PATH`. OUTDIR gets one `PATH.ts` per file
-- (slashes in PATH written as `__`): `@@ TSLANG PATH`, then
-- one `ROW START END CAPTURE` per capture (rows and byte columns 0-based, END
-- exclusive; a node spanning rows is split per row), in the order a
-- highlighter applies them (a later capture of the same bytes wins).
--
-- Needs the nvim-treesitter plugin's parser/ and queries/ on the runtime
-- path: set NVIM_TS_RTP to that directory (default: lazy's checkout). Nothing
-- is installed or written outside OUT.

local manifest, out_dir = arg[1], arg[2]
local rtp = os.getenv("NVIM_TS_RTP") or (os.getenv("HOME") .. "/.local/share/nvim/lazy/nvim-treesitter")
vim.opt.runtimepath:append(rtp)

local out

local function dump(lang, path)
  out = assert(io.open(out_dir .. "/" .. path:gsub("/", "__") .. ".ts", "w"))
  local f = io.open(path, "rb")
  if not f then out:write("!! " .. path .. ": unreadable\n") out:close() return end
  local text = f:read("*a")
  f:close()
  local ok, err = pcall(function()
    local lines = vim.split(text, "\n", { plain = true })
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    local parser = vim.treesitter.get_parser(buf, lang)
    parser:parse(true)
    out:write("@@ " .. lang .. " " .. path .. "\n")
    parser:for_each_tree(function(tree, ltree)
      local tlang = ltree:lang()
      local query = vim.treesitter.query.get(tlang, "highlights")
      if not query then return end
      for id, node, meta in query:iter_captures(tree:root(), buf, 0, -1) do
        local name = query.captures[id]
        if name ~= "spell" and name ~= "nospell" then
          local srow, scol, erow, ecol = node:range()
          if meta and meta.range then srow, scol, erow, ecol = meta.range[1], meta.range[2], meta.range[3], meta.range[4] end
          for row = srow, erow do
            local line = lines[row + 1] or ""
            local a = (row == srow) and scol or 0
            local b = (row == erow) and ecol or #line
            if b > a then
              out:write(string.format("%d %d %d %s\n", row, a, b, name))
            end
          end
        end
      end
    end)
    vim.api.nvim_buf_delete(buf, { force = true })
  end)
  if not ok then out:write("!! " .. path .. ": " .. tostring(err) .. "\n") end
  out:close()
end

for line in io.lines(manifest) do
  local lang, path = line:match("^(%S+)\t(.+)$")
  if lang then dump(lang, path) end
end
