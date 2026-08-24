# PyQt / Nuitka GUI Reverse Notes

## QApplication Probes

Always start with `QApplication.instance()`. Dump:
- `app.topLevelWidgets()`
- main window class/title/geometry/visibility
- `QStackedWidget.currentWidget()`
- visible dialogs and their child `QLabel`, `QTextEdit`, `QCheckBox`, `QPushButton`

For PyQt, many real blockers are modal dialogs or hidden stacked pages, not crashes.

## Widget Tree

Useful attributes to inspect:
- main buttons: `btn_*`
- stacked panels: `left_panel_stack`, `right_panel_stack`, `*_panel_widget`
- selected state: `current_panel`, `selected_*`
- workers/timers: `*_worker`, `*_timer`, `isRunning()`, `isFinished()`
- logs: `append_log`, `log_edit.toPlainText()`

If an attribute is a string like `current_panel='toolbox'`, do not treat it as a widget.

## Method Wrapping

Wrap one method at a time:
- log `ENTER`, args, selected state
- call original
- log `EXIT`, result, selected state
- on exception, log full traceback and re-raise

Patch idempotently:
- store original as `_orig_<name>` or `_zcm_orig_<name>`
- set a version flag like `_zcm_patch_version`
- avoid reconnecting Qt signals repeatedly

## GUI Click Path

For menu/sidebar issues:
1. Dump target button text/object/class.
2. Click once.
3. Check visible dialog.
4. Check stacked widget current pages.
5. Check whether target method fired.
6. Only then patch.

If clicking a button produces a prompt like "please import files first", fix workflow/state rather than treating it as a crash.
