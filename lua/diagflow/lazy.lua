

local M = {}

local function len(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end

local group = nil

local error = function(message)
    vim.notify(message, vim.log.levels.ERROR)
end

M.cached = {}
M.notifications = {}

local function update_cached_diagnostic()
    local bufnr = vim.api.nvim_get_current_buf()
    local ok, diagnostics = pcall(vim.diagnostic.get, bufnr)

    if not ok then
        error('Failed to get diagnostic: ' .. diagnostics)
        return
    end

    if type(diagnostics) ~= "table" then
        error('Diagnostic is not a table ' .. diagnostics)
        return
    end

    ok, diagnostics = pcall(function()
        table.sort(diagnostics, function(a, b) return a.severity < b.severity end)
        return diagnostics
    end)

    if not ok then
        error('Failed to sort diagnostics ' .. diagnostics)
        return
    end


    M.cached[bufnr] = diagnostics
end



function M.init(config)
    vim.diagnostic.config({ virtual_text = false })
    M.config = config

    local signs = (function()
      local signs = {}
      local type_diagnostic = vim.diagnostic.severity
      for _, severity in ipairs(type_diagnostic) do
        local status, sign = pcall(function()
          return vim.trim(
            vim.fn.sign_getdefined(
              "DiagnosticSign" .. severity:lower():gsub("^%l", string.upper)
            )[1].text
          )
        end)
        if not status then
          sign = severity:sub(1, 1)
        end
        signs[severity] = sign
      end
      return signs
    end)()

    local function render_diagnostics()
        if type(M.config.enable) == "function" then
            if not M.config.enable() then
                return
            end
        elseif not M.config.enable then
            return
        end

        local is_diagnostics_disabled = false

        if vim.fn.has("nvim-0.11") == 1 then
            is_diagnostics_disabled = vim.diagnostic.is_enabled ~= nil and not vim.diagnostic.is_enabled()
        else
            is_diagnostics_disabled = vim.diagnostic.is_disabled ~= nil and vim.diagnostic.is_disabled(0)
        end

        if is_diagnostics_disabled then
            return
        end


        -- Clear existing diagnostic notifications
        for k, notif in ipairs(M.notifications) do
            MiniNotify.remove(notif)
            M.notifications[k] = nil
        end

        local diags = M.cached[vim.api.nvim_get_current_buf()] or {}

        -- Get the current position
        local cursor_pos = vim.api.nvim_win_get_cursor(0)
        local line = cursor_pos[1] - 1 -- Subtract 1 to convert to 0-based indexing
        local col = cursor_pos[2]

        local current_pos_diags = {}
        for _, diag in ipairs(diags) do
                if config.scope == 'line' and diag.lnum == line or
                    config.scope == 'cursor' and diag.lnum == line and diag.col <= col and (diag.end_col or diag.col) >= col then
                    table.insert(current_pos_diags, diag)
                end
        end

        local notification_level_lookup = {
            [vim.diagnostic.severity.ERROR] = 'ERROR',
            [vim.diagnostic.severity.WARN] = 'WARN',
            [vim.diagnostic.severity.INFO] = 'INFO',
            [vim.diagnostic.severity.HINT] = 'DEBUG',
        }

        local hl_group_lookup = {
            [vim.diagnostic.severity.ERROR] = 'DiagnosticError',
            [vim.diagnostic.severity.WARN] = 'DiagnosticWarn',
            [vim.diagnostic.severity.INFO] = 'DiagnosticInfo',
            [vim.diagnostic.severity.HINT] = 'DiagnosticHint',
        }

        -- Render current_pos_diags
        for _, diag in ipairs(current_pos_diags) do
            local diag_message = config.format(diag)

            local level = notification_level_lookup[diag.severity]
            local hl_group = hl_group_lookup[diag.severity]

            table.insert(M.notifications, MiniNotify.add(diag_message, level, hl_group, {source='lsp_diagnostic'}))

        end
    end
    local function toggle()
        M.config.enable = not M.config.enable
    end

    if len(config.toggle_event) > 0 then
        vim.api.nvim_create_autocmd(config.toggle_event, {
            callback = toggle,
            pattern = "*",
            group = group
        })
    end
    vim.api.nvim_create_autocmd(config.update_event, {
        callback = update_cached_diagnostic,
        pattern = "*",
        group = group
    })

    vim.api.nvim_create_autocmd(config.render_event, {
        callback = render_diagnostics,
        pattern = "*",
        group = group
    })

    vim.api.nvim_create_autocmd('BufDelete', {
        group = group,
        callback = function(ev) M.cached[ev.buf] = nil end,
    })

    update_cached_diagnostic()
end

return M
