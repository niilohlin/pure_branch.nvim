
local result = ''
local last_time_called = 0

local function get_git_status()

  if vim.loop.now() - last_time_called < 1000 then
    return result
  end

  -- Get the current branch name
  vim.fn.jobstart({ 'git', 'rev-parse', '--abbrev-ref', 'HEAD' }, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      if data then
        result = data[1]
      end
      vim.fn.jobstart({ 'git', 'status', '--porcelain', '-u' }, {
        stdout_buffered = true,
        on_stdout = function(_, data)
          if data and #data > 0 and not result:find("%*") then
            result = result .. '*'
          end
          vim.fn.jobstart({ 'git', 'rev-list', '--left-right', '--count', 'HEAD...@{u}' }, {
            stdout_buffered = true,
            on_stdout = function(_, data)
              if data and #data > 0 then
                local ahead, behind = data[1]:match('^(%d+)%s+(%d+)$')
                ahead = tonumber(ahead)
                behind = tonumber(behind)

                if ahead > 0 then
                  result = result .. '⇡'
                end
                if behind > 0 then
                  result = result .. '⇣'
                end
              end
            end,
            on_exit = function()
              last_time_called = vim.loop.now()
            end,
          })
        end,
      })
    end,
  })
  return result
end

return get_git_status
