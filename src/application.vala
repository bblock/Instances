/* application.vala
 *
 * Copyright 2023 bwblock
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

public class MyApplication: Gtk.Application
{
   public static string app_id = "com.github.bblock.instances";
      // The app's reverse domain identifier.
   private static bool creating_new_tab = false;
   private static bool creating_new_window = false;

   const OptionEntry[] ENTRIES =
   {
      { "new-tab", 't', 0, OptionArg.NONE, null, "Create a new tab", null },
      { "new-window", 'w', 0, OptionArg.NONE, null, "Open a new window", null },
      { "version", 'v', 0, OptionArg.NONE, null, "Display app version", null },
      { GLib.OPTION_REMAINING, 0, 0, OptionArg.FILENAME_ARRAY, null, null, "[FILE…]" },
      { null }
   };
        
   construct
   {
      flags |= ApplicationFlags.HANDLES_OPEN;
      flags |= ApplicationFlags.HANDLES_COMMAND_LINE;
      application_id = app_id;
      GLib.Intl.setlocale(LocaleCategory.ALL, "");
      add_main_option_entries(ENTRIES);
   }

   protected override void activate()
   {
      if (active_window == null) 
      {
         // No windows. App is being launched.

         add_window(new Instances.Window(this));
      }
      else if (creating_new_window)
      {
         // App is already launched. Add another window to it:

         creating_new_window = false;
         add_window(new Instances.Window(this));
      }

      active_window.present();

      if (creating_new_tab)
      {
         // Create a new tab/document:

         creating_new_tab = false;
         ((Instances.Window) active_window).construct_tab(null);
      }
   }

   public override void startup()
   {
      base.startup();
  
      var new_window_action = new SimpleAction("new-window", null);
      new_window_action.activate.connect(on_new_window);
      add_action(new_window_action);
      set_accels_for_action("app.new-window", { "<Control><Shift>N" });

      var quit_action = new SimpleAction("quit", null);
      quit_action.activate.connect(on_quit);
      add_action(quit_action);
      set_accels_for_action("app.quit", { "<Control><Shift>Q" });
   }

   // Creates a new window. Is invoked on new-window action.
   private void on_new_window()
   {
      new Instances.Window(this).present();
   }

   // Processes any document file arguments 
   // that are passed on the command line.
   protected override void open(File[] files, string hint)
   {
      var win = active_window;

      if (win != null)
      {
         foreach (var file in files)
         {
            ((Instances.Window) win).open_file(file);
         }
      }
   }

   public override int handle_local_options(VariantDict options)
   {
      if (options.contains("version"))
      {
         stdout.printf ("Instances 0.1\n");
         return 0;
      }

      return -1;
   }

   // Handles both the options (switches) and the document 
   // file arguments that are passed on the command line.
   public override int command_line(GLib.ApplicationCommandLine command_line)
   {
      var options = command_line.get_options_dict();

      if (options.contains("new-tab"))
      {
         creating_new_tab = true;
      }

      if (options.contains("new-window"))
      {
         creating_new_window = true;
      }
      
      activate();

      if (options.contains(GLib.OPTION_REMAINING))
      {
         // Document file arguments were passed. Parse them:

         File[] files = {};

         (unowned string)[] remaining = options.lookup_value(GLib.OPTION_REMAINING, 
         VariantType.BYTESTRING_ARRAY).get_bytestring_array();

         for (int i = 0; i < remaining.length; i++)
         {
            unowned string file = remaining[i];
            files += command_line.create_file_for_arg(file);
         }

         open(files, "");
      }

      return 0;
   }

   // Shuts down the application completely by closing all of its windows.
   private void on_quit()
   {
      foreach (var win in get_windows())
      {
         win.close();
      }
   }

   public static int main(string[] args) 
   {
      MyApplication app = new MyApplication();
      return app.run(args);
   }
}
