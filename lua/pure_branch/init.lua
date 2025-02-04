local uv = vim.uv or vim.loop

local result = ''
local last_time_called = 0

local function get_git_status()
  if uv.now() - last_time_called < 1000 then
    return result
  end

  vim.fn.jobstart({ 'git', 'rev-parse', '--is-inside-work-tree' }, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      if not data or data[1] ~= 'true' then
        result = ''
        return
      end
      -- Get the current branch name
      vim.fn.jobstart({ 'git', 'rev-parse', '--abbrev-ref', 'HEAD' }, {
        stdout_buffered = true,
        on_stdout = function(_, data)
          if data and data[1] then
            result = data[1]
          else
            result = '(unknown branch)'
          end

          vim.fn.jobstart({ 'git', 'status', '--porcelain', '-u' }, {
            stdout_buffered = true,
            on_stdout = function(_, data)
              if data and #data > 0 and not result:find('%*') then
                result = result .. '*'
              end

              vim.fn.jobstart({ 'git', 'rev-list', '--left-right', '--count', 'HEAD...@{u}' }, {
                stdout_buffered = true,
                on_stdout = function(_, data)
                  if data and data[1] then
                    local ahead, behind = data[1]:match('^(%d+)%s+(%d+)$')
                    ahead = tonumber(ahead) or 0
                    behind = tonumber(behind) or 0

                    if ahead > 0 then
                      result = result .. '⇡'
                    end
                    if behind > 0 then
                      result = result .. '⇣'
                    end
                  end
                end,
              })
            end,
          })
        end,
      })
    end,
  })

  last_time_called = uv.now()
  return result
end

return get_git_status
