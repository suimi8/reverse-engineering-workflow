import functools
import os
import time
import traceback


LOG = os.path.join(os.getcwd(), "pyqt_method_trace.log")
TARGET_METHOD_NAMES = [
    # Example: "show_shortdrama_panel", "open_video_split_dialog"
]


def suimi_log(msg):
    with open(LOG, "a", encoding="utf-8") as f:
        f.write(time.strftime("%Y-%m-%d %H:%M:%S ") + str(msg) + "\n")


def suimi_short(value, limit=240):
    try:
        text = repr(value)
    except Exception as exc:
        text = f"<repr-error {exc!r}>"
    return text if len(text) <= limit else text[:limit] + "...<truncated>"


def suimi_dump_state(obj, label):
    for attr in ("current_panel", "selected_engine", "session_id"):
        try:
            if hasattr(obj, attr):
                suimi_log(f"{label}.{attr}={suimi_short(getattr(obj, attr))}")
        except Exception:
            pass
    for attr in ("left_panel_stack", "right_panel_stack"):
        try:
            stack = getattr(obj, attr, None)
            if stack is not None and hasattr(stack, "currentWidget"):
                cur = stack.currentWidget()
                suimi_log(f"{label}.{attr}.current={suimi_short(cur)}")
        except Exception as exc:
            suimi_log(f"{label}.{attr}.error={exc!r}")


def suimi_wrap_method(cls, name):
    orig = getattr(cls, name, None)
    if not callable(orig) or getattr(orig, "_trace_wrapped", False):
        return False

    @functools.wraps(orig)
    def suimi_wrapper(self, *args, **kwargs):
        suimi_log(f"ENTER {name} args={suimi_short(args)} kwargs={suimi_short(kwargs)}")
        suimi_dump_state(self, name + ".before")
        try:
            result = orig(self, *args, **kwargs)
            suimi_log(f"EXIT  {name} result={suimi_short(result)}")
            suimi_dump_state(self, name + ".after")
            return result
        except Exception:
            suimi_log(f"EXC   {name}\n{traceback.format_exc()}")
            suimi_dump_state(self, name + ".except")
            raise

    suimi_wrapper._trace_wrapped = True
    setattr(cls, name, suimi_wrapper)
    return True


def suimi_main():
    from PyQt5 import QtWidgets

    app = QtWidgets.QApplication.instance()
    suimi_log(f"app={app!r}")
    if not app:
        return
    target = None
    for w in app.topLevelWidgets():
        try:
            if w.__class__.__name__ == "VideoProcessorUI" or "招财猫" in w.windowTitle():
                target = w
                break
        except Exception:
            pass
    suimi_log(f"target={target!r}")
    if not target:
        return
    cls = type(target)
    for name in TARGET_METHOD_NAMES:
        try:
            suimi_log(f"wrap {name} -> {suimi_wrap_method(cls, name)}")
        except Exception:
            suimi_log(f"wrap_error {name}\n{traceback.format_exc()}")


suimi_main()
