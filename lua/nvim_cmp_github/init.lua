local source = {}
local Job = require'plenary.job'

---Source constructor.
source.new = function()
  local self = setmetatable({ cache = {} }, { __index = source })
  return self
end

---Return the source is available or not.
---@return boolean
function source:is_available()
  return vim.bo.filetype == "gitcommit"
end

---Return the source name for some information.
function source:get_debug_name()
  return 'github'
end

function source:get_trigger_characters()
  return { '#' }
end

---Invoke completion (required).
---  If you want to abort completion, just call the callback without arguments.
---@param _ cmp.SourceCompletionApiParams
---@param callback fun(response: lsp.CompletionResponse|nil)
function source:complete(_, callback)
  local bufnr = vim.api.nvim_get_current_buf()

  if not self.cache[bufnr] then
    Job:new({
      "gh",
      "pr",
      "list",
      "--limit",
      "1000",
      "--state",
      "all",
      "--json",
      "number,title,body",
      on_exit = function(job)
        local result = job:result()
        local ok, parsed = pcall(vim.json.decode, table.concat(result, ""))

        if not ok then
          return
        end

        local items = {}

        for _, gh_pr in ipairs(parsed) do
          gh_pr.body = string.gsub(gh_pr.body or "", "\r", "")

          table.insert(items, {
            label = string.format("#%s %s", gh_pr.number, gh_pr.title),
            insertText = tostring(gh_pr.number),
            documentation = {
              kind = "markdown",
              value = string.format("# %s\n\n%s", gh_pr.title, gh_pr.body),
            },
          })
        end

        self.cache[bufnr] = items

        callback({ items = self.cache[bufnr], isIncomplete = false })
      end
    }):start()
  else
    callback({ items = self.cache[bufnr], isIncomplete = false })
  end
end

require('cmp').register_source('github', source.new())
