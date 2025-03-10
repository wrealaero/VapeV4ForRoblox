local isfile = isfile or function(file)
	local suc, res = pcall(function()
		return readfile(file)
	end)
	return suc and res ~= nil and res ~= ''
end
local delfile = delfile or function(file)
	writefile(file, '')
end

local function downloadFile(path, func)
	if not isfile(path) then
		local suc, res = pcall(function()
			local commit = isfile('newvape/profiles/commit.txt') and readfile('newvape/profiles/commit.txt') or 'main'
			return game:HttpGet('https://raw.githubusercontent.com/wrealaero/VapeV4ForRoblox/'..commit..'/'..path:gsub('newvape/', ''), true)
		end)
		if not suc or res == '404: Not Found' then
			error(res)
		end
		if path:find('.lua') then
			res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res
		end
		writefile(path, res)
	end
	return (func or readfile)(path)
end

local function wipeFolder(path)
	if not isfolder(path) then return end
	for _, file in listfiles(path) do
		if file:find('loader') then continue end
		if isfile(file) and select(1, readfile(file):find('--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.')) == 1 then
			delfile(file)
		end
	end
end

for _, folder in {'newvape', 'newvape/games', 'newvape/profiles', 'newvape/assets', 'newvape/libraries', 'newvape/guis'} do
	if not isfolder(folder) then
		makefolder(folder)
	end
end

local commitFile = 'newvape/profiles/commit.txt'
local commit = 'main'

if not shared.VapeDeveloper then
	local success, subbed = pcall(function()
		return game:HttpGet('https://github.com/wrealaero/VapeV4ForRoblox')
	end)

	if not success or not subbed or subbed == '' then
		error("Failed to fetch repository data.")
	end

	local commitIndex = subbed:find('currentOid')
	if commitIndex then
		commit = subbed:sub(commitIndex + 13, commitIndex + 52)
		if #commit ~= 40 then commit = 'main' end
	end

	-- Ensure `commit.txt` exists before reading
	if isfile(commitFile) then
		local commitContents = readfile(commitFile)
		if commitContents ~= '' then
			commit = commitContents
		end
	end

	if commit == 'main' or (isfile(commitFile) and readfile(commitFile) ~= commit) then
		wipeFolder('newvape')
		wipeFolder('newvape/games')
		wipeFolder('newvape/guis')
		wipeFolder('newvape/libraries')
	end
	
	writefile(commitFile, commit)
end

-- Debugging Information (Move Before `return`)
print("Commit hash:", commit)
print("Downloading main.lua...")

local mainScript = downloadFile('newvape/main.lua')
if not mainScript or mainScript == '' then
    error("Failed to load main.lua")
end

-- Return after debug prints
return loadstring(mainScript, 'main')()
