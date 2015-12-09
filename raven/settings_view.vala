/*
 * This file is part of arc-desktop
 * 
 * Copyright (C) 2015 Ikey Doherty <ikey@solus-project.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

namespace Arc
{

public enum ThemeType {
    ICON_THEME,
    GTK_THEME,
    WM_THEME,
    CURSOR_THEME
}

[GtkTemplate (ui = "/com/solus-project/arc/raven/panel.ui")]
public class PanelEditor : Gtk.Box
{

}

[GtkTemplate (ui = "/com/solus-project/arc/raven/settings.ui")]
public class SettingsHeader : Gtk.Box
{
    private SettingsView? view = null;

    [GtkCallback]
    private void exit_clicked()
    {
        this.view.view_switch();
    }

    public SettingsHeader(SettingsView? view)
    {
        this.view = view;
    }
}

[GtkTemplate (ui = "/com/solus-project/arc/raven/appearance.ui")]
public class AppearanceSettings : Gtk.Box
{

    [GtkChild]
    private Gtk.ComboBox? combobox_gtk;

    [GtkChild]
    private Gtk.ComboBox? combobox_icon;

    [GtkChild]
    private Gtk.Switch? switch_dark;

    private GLib.Settings ui_settings;
    private GLib.Settings arc_settings;

    construct {
        var render = new Gtk.CellRendererText();
        combobox_gtk.pack_start(render, true);
        combobox_gtk.add_attribute(render, "text", 0);
    
        combobox_icon.pack_start(render, true);
        combobox_icon.add_attribute(render, "text", 0);

        ui_settings = new GLib.Settings("org.gnome.desktop.interface");
        arc_settings = new GLib.Settings("com.solus-project.arc-panel");
        arc_settings.bind("dark-theme", switch_dark, "active", SettingsBindFlags.DEFAULT);
    }

    public void load_themes()
    {
        load_themes_by_type.begin(ThemeType.GTK_THEME, (obj,res)=> {
            bool b = load_themes_by_type.end(res);
            combobox_gtk.sensitive = b;
            queue_resize();
            if (b) {
                ui_settings.bind("gtk-theme", combobox_gtk, "active-id", SettingsBindFlags.DEFAULT);
            }
        });
        load_themes_by_type.begin(ThemeType.ICON_THEME, (obj,res)=> {
            bool b = load_themes_by_type.end(res);
            combobox_icon.sensitive = b;
            queue_resize();
            if (b) {
                ui_settings.bind("icon-theme", combobox_icon, "active-id", SettingsBindFlags.DEFAULT);
            }
        });
    }

    /* Load theme list */
    async bool load_themes_by_type(ThemeType type)
    {
        var spc = Environment.get_system_data_dirs();
        spc += Environment.get_user_data_dir();
        string[] search = {};
        string? item = "";
        string? suffix = "";
        string[] results = {};
        FileTest test_type = FileTest.IS_DIR;

        unowned Gtk.ComboBox? target = null;
        Gtk.ListStore? model = null;
        Gtk.TreeIter iter;

        switch (type) {
            case ThemeType.GTK_THEME:
                item = "themes";
                suffix = "gtk-3.0";
                target = this.combobox_gtk;
                break;
            case ThemeType.ICON_THEME:
                item = "icons";
                suffix = "index.theme";
                test_type = FileTest.IS_REGULAR;
                target = this.combobox_icon;
                break;
            case ThemeType.CURSOR_THEME:
                item = "icons";
                suffix = "cursors";
                break;
            default:
                return false;
        }

        if (target == null) {
            return false;
        }

        model = new Gtk.ListStore(1, typeof(string));

        foreach (var dir in spc) {
            // Not making FS assumptions ftw.
            dir = (dir + Path.DIR_SEPARATOR_S +  item);
            if (FileUtils.test(dir, FileTest.IS_DIR)) {
                search += dir;
            }
        }
        string home = Environment.get_home_dir() + Path.DIR_SEPARATOR_S + "." + item;
        if (FileUtils.test(home, FileTest.IS_DIR)) {
            search += home;
        }

        foreach (var dir in search) {
            File f = File.new_for_path(dir);
            try {
                var en = yield f.enumerate_children_async("standard::*", FileQueryInfoFlags.NOFOLLOW_SYMLINKS, Priority.DEFAULT, null);
                while (true) {
                    var files = yield en.next_files_async(10, Priority.DEFAULT, null);
                    if (files == null) {
                        break;
                    }
                    foreach (var file in files) {
                        var display_name = file.get_display_name();
                        var test_path = dir + Path.DIR_SEPARATOR_S + display_name + Path.DIR_SEPARATOR_S + suffix;
                        if (!(display_name in results) && FileUtils.test(test_path, test_type)) {
                            results += display_name;
                            model.append(out iter);
                            model.set(iter, 0, display_name, -1);
                        }
                    }
                }
            } catch (Error e) {
                message("Error: %s", e.message);
            }
        }
        target.set_id_column(0);
        model.set_sort_column_id(0, Gtk.SortType.ASCENDING);
        target.set_model(model);
        return true;
    }
}

public class SettingsView : Gtk.Box
{

    public signal void view_switch();

    private Gtk.Stack? stack = null;
    private Gtk.StackSwitcher? switcher = null;

    public SettingsView()
    {
        Object(orientation: Gtk.Orientation.VERTICAL, spacing: 0);

        var header = new SettingsHeader(this);
        pack_start(header, false, false, 0);

        stack = new Gtk.Stack();
        stack.margin_top = 6;

        switcher = new Gtk.StackSwitcher();
        switcher.halign = Gtk.Align.CENTER;
        switcher.valign = Gtk.Align.CENTER;
        switcher.margin_top = 4;
        switcher.margin_bottom = 4;
        switcher.set_stack(stack);
        var sbox = new Gtk.EventBox();
        sbox.add(switcher);
        pack_start(sbox, false, false, 0);
        sbox.get_style_context().add_class("raven-switcher");

        pack_start(stack, true, true, 0);

        var appearance = new AppearanceSettings();
        stack.add_titled(appearance, "appearance", "General");

        var panel = new PanelEditor();
        stack.add_titled(panel, "panel", "Panel");
        stack.add_titled(new Gtk.Box(Gtk.Orientation.VERTICAL, 0), "sidebar", "Sidebar");

        appearance.load_themes();

        show_all();
    }
}

} /* End namespace */

/*
 * Editor modelines  -  https://www.wireshark.org/tools/modelines.html
 *
 * Local variables:
 * c-basic-offset: 4
 * tab-width: 4
 * indent-tabs-mode: nil
 * End:
 *
 * vi: set shiftwidth=4 tabstop=4 expandtab:
 * :indentSize=4:tabSize=4:noTabs=true:
 */