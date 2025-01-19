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
local function check_git_status(callback)
  local repo_path = vim.fn.getcwd()

  local result = ""

  -- Function to check for pushes
  local function check_push()
    vim.fn.jobstart({ "git", "status", "--porcelain", "--branch" }, {
      cwd = repo_path,
      stdout_buffered = true,
      on_stdout = function(_, data, _)
        if data then
          for _, line in ipairs(data) do
            if line:match("ahead") then
              result = result .. "⇡"
              break
            end
          end
        end
      end,
      on_exit = function()
        callback(result)
      end,
    })
  end

  -- Job to check for pulls
  vim.fn.jobstart({ "git", "fetch", "--dry-run" }, {
    cwd = repo_path,
    stdout_buffered = true,
    on_stdout = function(_, data, _)
      if data and table.concat(data) ~= table.concat({ "" }) then
        result = result .. "⇣"
      end
    end,
    on_exit = function()
      check_push()
    end,
  })
end
local cached_check_git_status = cache(check_git_status, 5000)


--- Check if the repository has uncommitted changes.
--- @param callback function: Function to call with the result ("*" or "").
local function check_git_dirty(callback)
  local repo_path = vim.fn.getcwd()

  vim.fn.jobstart({ "git", "status", "--porcelain" }, {
    cwd = repo_path,
    stdout_buffered = true,
    on_stdout = function(_, data, _)
      if data and not vim.tbl_isempty(data) then
        callback("*")
      else
        callback("")
      end
    end,
    on_exit = function()
    end,
  })
end
local cached_check_git_dirty = cache(check_git_dirty, 5000)

local function check_branch_name(callback)
  local repo_path = vim.fn.getcwd()

  vim.fn.jobstart({ "git", "branch", "--show-current" }, {
    cwd = repo_path,
    stdout_buffered = true,
    on_stdout = function(_, data, _)
      if data and not vim.tbl_isempty(data) then
        callback(data[1])
      else
        callback("")
      end
    end,
    on_exit = function()
    end,
  })
end
local cached_check_branch_name = cache(check_branch_name, 5000)


function M.pure_branch()
  return cached_check_branch_name() .. cached_check_git_dirty() .. " " .. cached_check_git_status()
end

return M
