/* window.vala
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

namespace Instances
{
   [GtkTemplate (ui = "/com/github/bblock/instances/window.ui")]
   public class Window : Gtk.ApplicationWindow
   {
      [GtkChild]
      private unowned Gtk.MenuButton menu_button;

      [GtkChild]
      private unowned Gtk.Notebook doc_notebook;

      public SimpleActionGroup actions { get; set; }
         // Collection of window related actions.

      public const string ACTION_GROUP = "win";
      public const string ACTION_PREFIX = ACTION_GROUP + ".";
      public const string ACTION_CLOSE_TAB = "close_tab";
      public const string ACTION_NEW_TAB = "new_tab";
      public const string ACTION_OPEN = "open";
      public const string ACTION_QUIT = "quit";
      public const string ACTION_SAVE = "save";
      public const string ACTION_SAVE_AS = "save_as";

      private const GLib.ActionEntry[] action_entries =
      {
        { ACTION_CLOSE_TAB, on_close_tab }, 
        { ACTION_NEW_TAB, on_new_tab }, 
        { ACTION_OPEN, on_open }, 
        { ACTION_QUIT, on_quit }, 
        { ACTION_SAVE, on_save }, 
        { ACTION_SAVE_AS, on_save_as }, 
      };
    
      // Constructor.
      public Window(MyApplication app)
      {
         Object(application: app);

         // Link actions to window:

         actions = new SimpleActionGroup();
         actions.add_action_entries(action_entries, this);
         insert_action_group(ACTION_GROUP, actions);

         // Set action accelerators:
         
         get_application().set_accels_for_action(ACTION_PREFIX + ACTION_CLOSE_TAB, {"<Ctrl>W"});
         get_application().set_accels_for_action(ACTION_PREFIX + ACTION_NEW_TAB, {"<Ctrl>N"});
         get_application().set_accels_for_action(ACTION_PREFIX + ACTION_OPEN, {"<Ctrl>O"});
         get_application().set_accels_for_action(ACTION_PREFIX + ACTION_QUIT, {"<Ctrl>Q"});
         get_application().set_accels_for_action(ACTION_PREFIX + ACTION_SAVE, {"<Ctrl>S"});

         // Build main menu:

         var builder = new Gtk.Builder.from_resource("/com/github/bblock/instances/menu.ui");
         Menu main_menu = (Menu) builder.get_object("main_menu");
         menu_button.menu_model = main_menu;

         this.show_all();
      }

      // Performs actual opening of a text document. Returns true if successful. 
      // Note: No check is done to ensure that a file isn't opened more than once.
      public bool open_file(File file)
      {
         bool result = false;
         var text_view = construct_tab(file);

         try 
         {
            // Load the file's contents into the textview widget:

            uint8[] contents;
            string etag_out;
            file.load_contents(null, out contents, out etag_out);
            text_view.buffer.text = (string) contents;
            result = true;
         }
         catch (Error e)
         {
            print("Error: %s\n", e.message);
         }
         
         return result;
      }

      // Closes the specified tab.
      private void close_tab(int page_index)
      {
         doc_notebook.remove_page(page_index);
      }

      // Attempts to close all tabs and returns true if successful.
      public bool try_close_window()
      {
         while ((doc_notebook.get_n_pages() > 0))
         {
            close_tab(0);
         }

         var closing = doc_notebook.get_n_pages() == 0;
         
         return closing;
      }

      // Creates a notebook tab's label widget.
      private Gtk.Widget create_tab_label(string text)
      {
         var label = new Gtk.Label(text);
         var image = new Gtk.Image.from_icon_name("window-close-symbolic", 
         Gtk.IconSize.BUTTON);
         var button = new Gtk.Button();
         button.relief = Gtk.ReliefStyle.NONE;
         ((Gtk.Widget) button).set_focus_on_click(false);
         button.add(image);
         button.clicked.connect(on_tab_close_button_click);
         var hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
         hbox.pack_start(label, false, false ,0);
         hbox.pack_start(button, false, false ,0);
         ((Gtk.Widget) hbox).set_has_tooltip (true);
         hbox.show_all();
         return hbox;
      }

      // Returns the page index corresponding to the 
      // given tab label or -1 if not found.
      private int get_page_index(string search_label)
      {
         int i;

         for (i=doc_notebook.get_n_pages()-1; i > -1; i--)
         {
            var scrolled_win = (Gtk.ScrolledWindow) doc_notebook.get_nth_page(i);
            Gtk.Box box = (Gtk.Box) doc_notebook.get_tab_label(scrolled_win);
            var children = box.get_children();
            unowned var child = children.first();
            string tab_label = ((Gtk.Label) child.data).label;
            if (tab_label == search_label) break;
         }

         return i;
      }
      
      // Returns a page's tab label given its index.
      private string get_tab_label(int page_index)
      {
         var scrolled_win = (Gtk.ScrolledWindow) doc_notebook.get_nth_page(page_index);
         Gtk.Box box = (Gtk.Box) doc_notebook.get_tab_label(scrolled_win);
         var children = box.get_children();
         unowned var child = children.first();
         return ((Gtk.Label) child.data).label;
      }
      
      // Returns true if an document is open based on the specified tab label.
      private bool tab_label_is_open(string tab_label)
      {
         for (int i = 0; i < doc_notebook.get_n_pages(); i++)
         {
            string the_label = get_tab_label(i);

            if (the_label == tab_label)
            {
               return true;
            }
         }

         return false;
      }
      
      // Generates the first available "new file" name.
      private string new_file_name()
      {
         int i = 1;
         string label_base = "new file ";

         while (tab_label_is_open(label_base + i.to_string()))
         { 
            i++;
         }

         return label_base + i.to_string();
      }
      
      // Creates a new notebook tab.
      public Gtk.TextView construct_tab(GLib.File? file)
      {
         var text_view = new Gtk.TextView();
         text_view.visible = true;
         text_view.can_focus = true;
         text_view.monospace = true;

         // Create and configure the scrolled window widget  
         // that will host the document's TextView widget:

         var scrolled_window = new Gtk.ScrolledWindow(null, null);
         scrolled_window.visible = true;
         scrolled_window.can_focus = true;
         scrolled_window.shadow_type = Gtk.ShadowType.IN;
         scrolled_window.add(text_view);

         // Get reference to document file to be  
         // stored into the notebook tab's label:

         string tab_label_text;
         
         if (file != null)
         {
            // The tab is being constructed to open an existing document.

            tab_label_text = file.get_basename();
         }
         else
         {
            // The tab is being constructed for a new document.

            tab_label_text = new_file_name();
         }

         // Add the new tab to the notebook and display it:

         int page_index = doc_notebook.append_page(scrolled_window, 
         create_tab_label(tab_label_text));
         doc_notebook.set_tab_reorderable(scrolled_window, true);

         // Select the new tab:

         doc_notebook.set_current_page(page_index);

         return text_view;
      }

      //----------------------------------------------------------------------//
      //                                Actions                               //
      //----------------------------------------------------------------------//

      private void on_close_tab()
      {
         doc_notebook.remove_page(doc_notebook.get_current_page());
      }

      private void on_new_tab()
      {
         construct_tab(null);
      }

      private void on_open()
      {
         // Create a new file selection dialog, using the "open" mode
         // and keep a reference to it:

         var filechooser = new Gtk.FileChooserNative("Open File", null,
         Gtk.FileChooserAction.OPEN, "_Open", "_Cancel") { transient_for = this };

         filechooser.response.connect((dialog, response) => 
         {
            if (response == Gtk.ResponseType.ACCEPT) 
            {
               // User selected a file. Retrieve it from the dialog and open it:

               GLib.File file = filechooser.get_file();
               open_file(file);
            }
         });

         filechooser.show();
      }

      private void on_quit()
      {
         if (try_close_window()) this.destroy();
      }

      private void on_save()
      {
         print("win.on_save() not implemented.\n");
      }

      private void on_save_as()
      {
         print("win.on_save_as() not implemented.\n");
      }

      //----------------------------------------------------------------------//
      //                             Notebook Events                          //
      //----------------------------------------------------------------------//
      
      private void on_tab_close_button_click(Gtk.Widget sender)
      {
         var box = (Gtk.Box) sender.parent;
         var children = box.get_children();
         unowned var child = children.first();
         string tab_label = ((Gtk.Label) child.data).label;
         int page_index = get_page_index(tab_label);
         if (page_index > -1) close_tab(page_index);
      }
   }
}
