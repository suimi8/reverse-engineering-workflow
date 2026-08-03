import ctypes
import sys
from ctypes import wintypes


EnumWindowsProc = ctypes.WINFUNCTYPE(wintypes.BOOL, wintypes.HWND, wintypes.LPARAM)
EnumChildProc = ctypes.WINFUNCTYPE(wintypes.BOOL, wintypes.HWND, wintypes.LPARAM)
user32 = ctypes.WinDLL("user32", use_last_error=True)

GetWindowTextW = user32.GetWindowTextW
GetClassNameW = user32.GetClassNameW
GetWindowThreadProcessId = user32.GetWindowThreadProcessId
IsWindowVisible = user32.IsWindowVisible
EnumChildWindows = user32.EnumChildWindows


def suimi_text(hwnd, size=512):
    buf = ctypes.create_unicode_buffer(size)
    GetWindowTextW(hwnd, buf, size)
    return buf.value


def suimi_klass(hwnd):
    buf = ctypes.create_unicode_buffer(256)
    GetClassNameW(hwnd, buf, 256)
    return buf.value


def suimi_pid_of(hwnd):
    pid = wintypes.DWORD()
    tid = GetWindowThreadProcessId(hwnd, ctypes.byref(pid))
    return int(pid.value), int(tid)


def suimi_dump_children(hwnd):
    rows = []

    @EnumChildProc
    def suimi_cb(child, _):
        rows.append((child, suimi_klass(child), suimi_text(child)))
        return True

    EnumChildWindows(hwnd, suimi_cb, 0)
    return rows


def suimi_main():
    target_pid = int(sys.argv[1]) if len(sys.argv) > 1 else 0

    @EnumWindowsProc
    def suimi_cb(hwnd, _):
        pid, tid = suimi_pid_of(hwnd)
        if target_pid and pid != target_pid:
            return True
        if not IsWindowVisible(hwnd):
            return True
        print(f"hwnd={hex(hwnd)} pid={pid} tid={tid} class={suimi_klass(hwnd)!r} title={suimi_text(hwnd)!r}")
        for child, cklass, ctext in suimi_dump_children(hwnd):
            if ctext or cklass == "Button":
                print(f"  child={hex(child)} class={cklass!r} text={ctext!r}")
        return True

    user32.EnumWindows(suimi_cb, 0)


if __name__ == "__main__":
    suimi_main()
