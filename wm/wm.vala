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

namespace Arc {


public static const string MUTTER_EDGE_TILING  = "edge-tiling";
public static const string MUTTER_MODAL_ATTACH = "attach-modal-dialog";
public static const string WM_SCHEMA           = "com.solus-project.arc.wm";

public class ArcWM : Meta.Plugin
{
    static Meta.PluginInfo info;

    static construct
    {
        info = Meta.PluginInfo() {
            name = "Arc WM",
            /*version = Arc.VERSION,*/
            version = "1",
            author = "Ikey Doherty",
            license = "GPL-2.0",
            description = "Arc Window Manager"
        };
    }

    public ArcWM()
    {
        Meta.Prefs.override_preference_schema(MUTTER_EDGE_TILING, WM_SCHEMA);
        Meta.Prefs.override_preference_schema(MUTTER_MODAL_ATTACH, WM_SCHEMA);
    }

    public override unowned Meta.PluginInfo? plugin_info() {
        return info;
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