import os
import time
import traceback


LOG = os.path.join(os.getcwd(), "pyqt_visible_dialogs_probe.log")


def suimi_log(msg):
    with open(LOG, "a", encoding="utf-8") as f:
        f.write(time.strftime("%Y-%m-%d %H:%M:%S ") + str(msg) + "\n")


def suimi_widget_text(widget):
    for attr in ("text", "toPlainText", "plainText", "windowTitle"):
        if hasattr(widget, attr):
            try:
                value = getattr(widget, attr)()
                if value:
                    return str(value)
            except Exception:
                pass
    return ""


def suimi_main():
    try:
        from PyQt5 import QtWidgets

        app = QtWidgets.QApplication.instance()
        suimi_log(f"app={app!r}")
        if not app:
            return
        for idx, w in enumerate(app.topLevelWidgets()):
            try:
                if not w.isVisible():
                    continue
                suimi_log(
                    f"top[{idx}] class={w.__class__.__module__}.{w.__class__.__name__} "
                    f"title={w.windowTitle()!r} visible={w.isVisible()} "
                    f"enabled={w.isEnabled()} geom={(w.x(), w.y(), w.width(), w.height())}"
                )
                for child in w.findChildren(QtWidgets.QWidget):
                    klass = child.metaObject().className()
                    if klass in ("QLabel", "QPushButton", "QCheckBox", "QTextEdit", "QPlainTextEdit"):
                        text = suimi_widget_text(child)
                        if text:
                            suimi_log(
                                f"  child class={klass} py={child.__class__.__module__}.{child.__class__.__name__} "
                                f"text={text!r} visible={child.isVisible()} enabled={child.isEnabled()}"
                            )
            except Exception:
                suimi_log("top_error\n" + traceback.format_exc())
    except Exception:
        suimi_log("main_error\n" + traceback.format_exc())


suimi_main()
