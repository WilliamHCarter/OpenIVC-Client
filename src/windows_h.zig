pub const cwin = @cImport({
    @cInclude("windows.h");
});

const client = @cImport({
    @cInclude("client.h");
});
