local M = {}

--- @alias FunCand fun():string
--- @alias CandOpt string|FunCand

--- Resolve a candidate input or nil if it fails resolving the candidate
--- @param candidate CandOpt: A candidate that needs to be resolve
--- @return string? path: location of a possible compile_commands.json file
local function resolve_candidate(candidate)
  if type(candidate) == 'string' then
    return candidate
  end

  if type(candidate) == "function" then
    local ok, cand = pcall(candidate)
    if ok then return cand end
  end
  return nil
end

--- Reads a compile_commands.json file and return it as a table on success else return nil
--- @param path string?: Path to compile_commands.json file
--- @return table? compile_commands: compile_commands structure
local function read_compile_commands(path)
  if path == nil then return nil end

  local file_ok, file = pcall(vim.fn.readfile, path)
  if not file_ok then return nil end

  local ok, json = pcall(vim.fn.json_decode, file)
  if not ok or type(json) ~= "table" or #json == 0 then return nil end

  return json
end

--- Check if the compiler used to build the project is in $PATH and if not it return it as the query-driver value
--- @param compile_commands table?
--- @return string? path: query-driver path.
local function extract_driver_path(compile_commands)
  if compile_commands == nil then return nil end
  if compile_commands[1].command == nil then return nil end

  local command = vim.split(compile_commands[1].command, "%s")[1]
  local path = vim.fn.fnamemodify(command, ':p:h')
  local program = vim.fn.fnamemodify(command, ':t')

  if vim.fn.executable(program) == 1 and os.getenv("CROSS_COMPILE") == nil then return nil end

  local prefix, _ = program:match("^(.-%-)([^-]+)$")

  return path .. '/' .. prefix .. "-*"
end

--- Parse '.clangd' search for a possible for compile_commands.json
--- @return string? path: Location of a compile_commands.json or nil
local function parse_clangd()
  local ok, lines = pcall(io.lines, ".clangd")
  if not ok then return nil end

  for line in lines do
    local m = line:match("CompilationDatabase:%s*(%S+)")
    if m then return m .. "/compile_commands.json" end
  end
end

--- Return query-driver flag if project configuration requires.
--- @param candidates CandOpt[]?: Candidates paths to look for compile_commands.json
--- @return string?
function M.get_query_driver_flag(candidates)
  candidates = candidates or {}

  local defaults = {
    './compile_commands.json',
    parse_clangd
  }

  for _, cand in ipairs(defaults) do table.insert(candidates, cand) end

  for _, candidate in ipairs(candidates) do
    local cand = resolve_candidate(candidate)
    local compile_commands = read_compile_commands(cand)
    local driver_path = extract_driver_path(compile_commands)
    if driver_path then
      return "--query-driver=" .. driver_path
    end
  end
end

return M
