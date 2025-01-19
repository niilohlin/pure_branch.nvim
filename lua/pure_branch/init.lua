local M = {}

local function cache(func, time)
  local cached_result = ""
  local last_check_time = 0

  return function()
    local current_time = vim.loop.now()
    if current_time - last_check_time < time then
      return cached_result
    end
    func(function(new_result)
      cached_result = new_result
      last_check_time = vim.loop.now()
    end)
    return cached_result
  end
end


--- Check the Git repository for updates asynchronously.
--- @param callback function: Function to call with the result ("⇣", "⇡", or "").
local function pure_branch(callback)
  local repo_path = vim.fn.getcwd()

  local branch_name = ""
  local result = ""

  vim.fn.jobstart({ "git", "fetch" }, {
    cwd = repo_path,
    stdout_buffered = true,
    on_stdout = function(_, data, _)
      vim.fn.jobstart({ "git", "branch", "--show-current" }, {
        cwd = repo_path,
        stdout_buffered = true,
        on_stdout = function(_, data, _)
          if data and table.concat(data) ~= "" then
            branch_name = data[1]
            result = branch_name
          end
          vim.fn.jobstart({ "git", "status", "--porcelain" }, {
            cwd = repo_path,
            stdout_buffered = true,
            on_stdout = function(_, data, _)
              if data and table.concat(data) ~= "" then
                result = result .. "*"
              end
            end,
            on_exit = function()
              vim.fn.jobstart({ "git", "status", "--porcelain", "--branch" }, {
                cwd = repo_path,
                stdout_buffered = true,
                on_stdout = function(_, data, _)
                  if data then
                    for _, line in ipairs(data) do
                      if line:match("ahead") then
                        result = result .. "⇡"
                      end
                      if line:match("behind") then
                        result = result .. "⇣"
                      end
                    end
                  end
                end,
                on_exit = function()
                  callback(result)
                end,
              })
            end,
          })
        end,
      })
    end
  })
end

local cached_pure_branch = cache(pure_branch, 5000)

function M.pure_branch()
  return cached_pure_branch()
end

return M
