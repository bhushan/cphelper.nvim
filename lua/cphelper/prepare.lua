local p = require("plenary.path")
local h = require("cphelper.helpers")
local defns = require("cphelper.definitions")
local contests_dir = p.new(vim.g.cphdir or (vim.loop.os_homedir() .. p.path.sep .. "contests"))
local preferred_lang = vim.g.cphlang or "cpp"

local M = {}

function M.prepare_folders(problem, group)
    local problem_dir
    if group == "UVa Online Judge" then
        problem_dir = contests_dir:joinpath("UVa", h.sanitize(problem))
    else
        local sep_pos = string.find(group, "% %-")
        local judge = h.sanitize(string.sub(group, 1, sep_pos))
        local contest = h.sanitize(string.sub(group, sep_pos + 1))
        problem = h.sanitize(problem)
        problem_dir = contests_dir:joinpath(judge, contest, problem)
    end
    problem_dir:mkdir({ exists_ok = true, parents = true })
    return problem_dir
end

function M.prepare_files(problem_dir, tests)
    for i, test in pairs(tests) do
        problem_dir:joinpath("input" .. i):write(test["input"], "w")
        problem_dir:joinpath("output" .. i):write(test["output"], "w")
    end
    print("Wrote tests")
    local extension = defns["extensions"][preferred_lang]
    problem_dir:joinpath("solution." .. extension):touch()
    print("Wrote solution files")

    if vim.g.cph_rust_createjson then
        problem_dir:joinpath("rust-project.json"):write(vim.g.rustjson or ([[
{
     "sysroot_src": "]] .. vim.loop.os_homedir() .. [[/.rustup/toolchains/stable-x86_64-unknown-linux-gnu/lib/rustlib/src/rust/library/",
     "crates": [
             {
                 "root_module": "solution.rs",
                 "edition": "2018",
                 "deps": []
            }
     ]
}
]]), "w")
        print("Wrote rust-project.json")
    end

    --    problem_dir:joinpath("Makefile"):write([[c:
    --	]] .. (vim.g.c_compile_command or defns.compile_cmd.c) .. [[
    --cpp:
    --	]] .. (vim.g.cpp_compile_command or defns.compile_cmd.cpp))
    --    print("Wrote makefile")

    vim.cmd("e " .. problem_dir:joinpath("solution." .. extension):absolute())
end

return M
