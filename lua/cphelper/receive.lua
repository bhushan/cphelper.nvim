local prepare = require("cphelper.prepare")
local uv = vim.loop

local M = {}

function M.receive()
    print("Listening on port 27121")
    local buffer = ""
    M.server = uv.new_tcp()
    M.server:bind("127.0.0.1", 27121)
    M.server:listen(128, function(err)
        assert(not err, err)
        local client = uv.new_tcp()
        M.server:accept(client)
        client:read_start(function(error, chunk)
            assert(not error, error)
            if chunk then
                buffer = buffer .. chunk
            else
                client:shutdown()
                client:close()

                local lines = {}
                for line in string.gmatch(buffer, "[^\r\n]+") do
                    table.insert(lines, line)
                end
                buffer = lines[#lines]

                vim.schedule(function()
                    local request = vim.json.decode(buffer)
                    if vim.g.cph_url_register then
                        vim.fn.setreg(vim.g.cph_url_register, request.url)
                    end
                    local problem_dir = prepare.prepare_folders(request.name, request.group)
                    prepare.prepare_files(problem_dir, request.tests)
                    print("All the best!")
                end)

                M.server:shutdown()
            end
        end)
    end)
    uv.run()
end

function M.stop()
    M.server:shutdown()
end

return M
