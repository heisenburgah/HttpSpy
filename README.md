# HttpSpy v2
A powerful and highly efficient network debugging tool for Roblox exploits - Modified by Heisenburgah
> Please don't use this on any commercial scripts, you'll most likely get yourself detected

## Updates in v2
- Removed all `syn` dependencies - now uses universal `request` function only
- Added request timing/performance tracking
- Added HTTP method filtering
- Added large response size warnings
- Enhanced console output with colorful prefixes
- Improved error handling

## Usage
> Be sure to execute the HttpSpy before the target script!
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/heisenburgah/HttpSpy/refs/heads/main/httpspy.lua"))({
    AutoDecode = true, -- Automatically decodes JSON
    Highlighting = true, -- Highlights the output
    SaveLogs = true, -- Save logs to a text file
    CLICommands = true, -- Allows you to input commands into the console
    ShowResponse = true, -- Shows the request response
    API = true, -- Enables the script API
    BlockedURLs = {}, -- Blocked urls
    FilterMethods = {}, -- Filter by HTTP methods (GET, POST, etc.)
    ShowTimings = true -- Show request timing information
});
```

## Features
- Request Reconstructing
- Syntax Highlighting
- Lightweight
- Auto JSON Decoding
- Easy to use
- Script API
- Universal `request` support (no syn dependency)
- Request timing and performance tracking
- HTTP method filtering
- Large response warnings
- Colorful console output with prefixes

## API
```lua
HttpSpy:HookRequest(<string url>, <function hook>); -- hook is called with <table Response>
HttpSpy:BlockUrl(<string url>);
HttpSpy:WhitelistUrl(<string url>);
HttpSpy:ProxyHost(<string host>, <string proxy>);
HttpSpy:RemoveProxy(<string host>);
HttpSpy:UnHookRequest(<string url>);
HttpSpy:SetMethodFilter(<table methods>); -- Filter by HTTP methods
HttpSpy:ToggleTimings(<boolean enabled>); -- Enable/disable timing info
HttpSpy:Toggle(<boolean enabled>); -- Enable/disable HttpSpy
HttpSpy.OnRequest<event>(<table request>);
```

### Example
```lua
local HttpSpy = loadstring(game:HttpGet("https://raw.githubusercontent.com/heisenburgah/HttpSpy/refs/heads/main/httpspy.lua"))({
    AutoDecode = true, -- Automatically decodes JSON
    Highlighting = true, -- Highlights the output
    SaveLogs = true, -- Save logs to a text file
    CLICommands = true, -- Allows you to input commands into the console
    ShowResponse = true, -- Shows the request response
    API = true, -- Enables the script API
    BlockedURLs = {}, -- Blocked urls
    FilterMethods = {"GET", "POST"}, -- Only show GET and POST requests
    ShowTimings = true -- Show request timing
});

HttpSpy.OnRequest:Connect(function(req) 
    warn("request made:", req.Url);    
end);

HttpSpy:HookRequest("https://httpbin.org/get", function(response) 
    response.Body = "hooked!";
    return response;
end);

print(request({ Url = "https://httpbin.org/get" }).Body);

HttpSpy:UnHookRequest("https://httpbin.org/get");
HttpSpy:ProxyHost("httpbin.org", "google.com");

-- Filter to only show POST requests
HttpSpy:SetMethodFilter({"POST"});

-- Toggle timing information
HttpSpy:ToggleTimings(false);

print(request({ Url = "https://httpbin.org/get" }).Body);
```

## Credits
- Original Creator: [NotDSF](https://github.com/NotDSF)
- Modified by: [Heisenburgah](https://github.com/heisenburgah)
