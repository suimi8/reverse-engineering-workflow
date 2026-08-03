// Frida hook template for authorized local/sandbox targets.
// Usage example: frida -f target.exe -l frida_hook_template.js --no-pause

function suimiReadWide(ptrValue) {
  try {
    return ptrValue.isNull() ? "" : ptrValue.readUtf16String();
  } catch (e) {
    return "<readUtf16String failed: " + e + ">";
  }
}

function suimiHookExport(moduleName, exportName, callbacks) {
  const addr = Module.findExportByName(moduleName, exportName);
  if (!addr) {
    console.log("missing " + moduleName + "!" + exportName);
    return;
  }
  console.log("hook " + moduleName + "!" + exportName + " @ " + addr);
  Interceptor.attach(addr, callbacks);
}

suimiHookExport("user32.dll", "MessageBoxW", {
  onEnter(args) {
    this.text = suimiReadWide(args[1]);
    this.title = suimiReadWide(args[2]);
    console.log("MessageBoxW title=" + JSON.stringify(this.title) + " text=" + JSON.stringify(this.text));
  },
  onLeave(retval) {
    console.log("MessageBoxW ret=" + retval);
  },
});

suimiHookExport("kernel32.dll", "ExitProcess", {
  onEnter(args) {
    console.log("ExitProcess code=" + args[0] + " caller=" + this.returnAddress);
  },
});
