--[[
    HttpSpy v2
]]

if rconsoleprint then
    rconsoleprint("\27[95m[>] \27[0mhttps://hydroxide.solutions - #1 Goopy\n\n")
end;

assert(request, "Unsupported exploit (should support request)");

local options = ({...})[1] or { AutoDecode = true, Highlighting = true, SaveLogs = true, CLICommands = true, ShowResponse = true, BlockedURLs = {}, API = true, FilterMethods = {}, ShowTimings = true };
local version = "v2";
local logname = string.format("%d-%s-log.txt", game.PlaceId, os.date("%d_%m_%y"));

if options.SaveLogs then
    writefile(logname, string.format("Http Logs from %s\n\n", os.date("%d/%m/%y"))) 
end;

local Serializer = loadstring(game:HttpGet("https://raw.githubusercontent.com/heisenburgah/leopard/main/rbx/leopard-syn.lua"))();
local clonef = clonefunction;
local pconsole = clonef(rconsoleprint);
local format = clonef(string.format);
local gsub = clonef(string.gsub);
local match = clonef(string.match);
local append = clonef(appendfile);
local Type = clonef(type);
local crunning = clonef(coroutine.running);
local cwrap = clonef(coroutine.wrap);
local cresume = clonef(coroutine.resume);
local cyield = clonef(coroutine.yield);
local Pcall = clonef(pcall);
local Pairs = clonef(pairs);
local Error = clonef(error);
local getnamecallmethod = clonef(getnamecallmethod);
local blocked = options.BlockedURLs;
local enabled = true;
local reqfunc = request;
local libtype = "request";
local hooked = {};
local proxied = {};
local methods = {
    HttpGet = true,
    HttpGetAsync = true,
    GetObjects = true,
    HttpPostAsync = true
}

Serializer.UpdateConfig({ highlighting = options.Highlighting });

local RecentCommit = game.HttpService:JSONDecode(game:HttpGet("https://api.github.com/repos/heisenburgah/HttpSpy/commits?per_page=1&path=init.lua"))[1].commit.message;
local OnRequest = Instance.new("BindableEvent");

local function printf(...) 
    local formatted = format(...);
    local withPrefix = "\27[36m[HttpSpy]\27[0m " .. formatted;
    if options.SaveLogs then
        append(logname, gsub(withPrefix, "%\27%[%d+m", ""));
    end;
    return pconsole(withPrefix);
end;

local function ConstantScan(constant)
    for i,v in Pairs(getgc(true)) do
        if type(v) == "function" and islclosure(v) and getfenv(v).script == getfenv(saveinstance).script and table.find(debug.getconstants(v), constant) then
            return v;
        end;
    end;
end;

local function DeepClone(tbl, cloned)
    cloned = cloned or {};

    for i,v in Pairs(tbl) do
        if Type(v) == "table" then
            cloned[i] = DeepClone(v);
            continue;
        end;
        cloned[i] = v;
    end;

    return cloned;
end;

local __namecall, __request;
__namecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local method = getnamecallmethod();

    if methods[method] then
        printf("game:%s(%s)\n\n", method, Serializer.FormatArguments(...));
    end;

    return __namecall(self, ...);
end));

__request = hookfunction(reqfunc, newcclosure(function(req) 
    if Type(req) ~= "table" then return __request(req); end;
    
    local RequestData = DeepClone(req);
    if not enabled then
        return __request(req);
    end;

    if Type(RequestData.Url) ~= "string" then return __request(req) end;

    -- Filter by method if specified
    if options.FilterMethods and #options.FilterMethods > 0 then
        local method = RequestData.Method or "GET";
        local shouldShow = false;
        for _, allowedMethod in Pairs(options.FilterMethods) do
            if method:upper() == allowedMethod:upper() then
                shouldShow = true;
                break;
            end;
        end;
        if not shouldShow then
            return __request(req);
        end;
    end;

    if not options.ShowResponse then
        printf("%s.request(%s)\n\n", libtype, Serializer.Serialize(RequestData));
        return __request(req);
    end;

    local t = crunning();
    cwrap(function() 
        if RequestData.Url and blocked[RequestData.Url] then
            printf("%s.request(%s) -- blocked url\n\n", libtype, Serializer.Serialize(RequestData));
            return cresume(t, {});
        end;

        if RequestData.Url then
            local Host = string.match(RequestData.Url, "https?://(%w+.%w+)/");
            if Host and proxied[Host] then
                RequestData.Url = gsub(RequestData.Url, Host, proxied[Host], 1);
            end; 
        end;

        OnRequest:Fire(RequestData);

        local startTime = options.ShowTimings and tick() or nil;
        local ok, ResponseData = Pcall(__request, RequestData);
        local endTime = options.ShowTimings and tick() or nil;
        local duration = startTime and endTime and (endTime - startTime) or nil;
        
        if not ok then
            if duration then
                printf("Request failed after %.3fs: %s\n", duration, tostring(ResponseData));
            end;
            Error(ResponseData, 0);
        end;

        local BackupData = {};
        for i,v in Pairs(ResponseData) do
            BackupData[i] = v;
        end;

        if BackupData.Headers["Content-Type"] and match(BackupData.Headers["Content-Type"], "application/json") and options.AutoDecode then
            local body = BackupData.Body;
            local ok, res = Pcall(game.HttpService.JSONDecode, game.HttpService, body);
            if ok then
                BackupData.Body = res;
            end;
        end;

        local timingInfo = duration and string.format(" [%.3fs]", duration) or "";
        local sizeInfo = "";
        if BackupData.Body and Type(BackupData.Body) == "string" then
            local bodySize = #BackupData.Body;
            if bodySize > 10000 then
                sizeInfo = string.format(" [%d bytes - Large Response!]", bodySize);
            end;
        end;
        
        printf("%s.request(%s)%s%s\n\nResponse Data: %s\n\n", libtype, Serializer.Serialize(RequestData), timingInfo, sizeInfo, Serializer.Serialize(BackupData));
        cresume(t, hooked[RequestData.Url] and hooked[RequestData.Url](ResponseData) or ResponseData);
    end)();
    return cyield();
end));


for method, enabled in Pairs(methods) do
    if enabled then
        local b;
        b = hookfunction(game[method], newcclosure(function(self, ...) 
            printf("game.%s(game, %s)\n\n", method, Serializer.FormatArguments(...));
            return b(self, ...);
        end));
    end;
end;

if not debug.info(2, "f") then
    pconsole("\27[93m[!] \27[0mYou are running an outdated version, please use the loadstring at https://github.com/heisenburgah/HttpSpy\n");
end;

pconsole(format("\27[92m[>] \27[0mHttpSpy %s (Creator: https://github.com/NotDSF | Modified by Heisenburgah)\n\27[94m[>] \27[0mChange Logs:\n\t%s\n\27[96m[>] \27[0mLogs are automatically being saved to: \27[32m%s\27[0m\n\n", version, RecentCommit, options.SaveLogs and logname or "(You aren't saving logs, enable SaveLogs if you want to save logs)"));

if not options.API then return end;

local API = {};
API.OnRequest = OnRequest.Event;

function API:HookRequest(url, hook) 
    hooked[url] = hook;
end;

function API:ProxyHost(host, proxy) 
    proxied[host] = proxy;
end;

function API:RemoveProxy(host) 
    if not proxied[host] then
        error("host isn't proxied", 0);
    end;
    proxied[host] = nil;
end;

function API:UnHookRequest(url) 
    if not hooked[url] then
        error("url isn't hooked", 0);
    end;
    hooked[url] = nil;
end

function API:BlockUrl(url) 
    blocked[url] = true;
end;

function API:WhitelistUrl(url) 
    blocked[url] = false;
end;

function API:SetMethodFilter(methods) 
    options.FilterMethods = methods or {};
end;

function API:ToggleTimings(enabled) 
    options.ShowTimings = enabled;
end;

function API:Toggle(enabled) 
    enabled = enabled;
end;

return API;
