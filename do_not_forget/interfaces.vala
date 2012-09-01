using Utils;
using Tasks;
using TaskCollections;
using TaskManagerNS;

namespace UserInterfaces {

    enum Responses {
        NONE,
        SHOW_COLLECTIONS,
        ADD_COLLECTION,
        REMOVE_COLLECTION,
        EDIT_COLLECTION,
        ADD_TASK,
        REMOVE_TASK,
        EDIT_TASK,
        ABOUT,
        QUIT
    }

    interface UserInterface : GLib.Object {

        public abstract void run ();

        public abstract TaskManager tasks_manager {
            get;
            set;
        }

    }

    class CommandLineInterface : GLib.Object, UserInterface {

        private TaskManager _manager;

        public TaskManager tasks_manager {
            get { return _manager; }
            set { _manager = value; }
        }

        public CommandLineInterface () {
            _manager = TaskManager.get_instance ();
        }

        /* Main method, that interacts with the user */
        public void run () {
            show_welcome();
            println ();
            Responses response = main_menu ();

            while (response != Responses.QUIT) {
                println ();
                switch (response) {
                    case Responses.SHOW_COLLECTIONS: response = show_collections ();
                                                     break;
                    case Responses.ADD_COLLECTION: response = add_collection ();
                                                   break;
                    case Responses.REMOVE_COLLECTION: response = remove_collection ();
                                                      break;
                    case Responses.EDIT_COLLECTION: response = edit_collection ();
                                                    break;
                    case Responses.ADD_TASK: response = add_task ();
                                             break;
                    case Responses.REMOVE_TASK: response = remove_task ();
                                                break;
                    case Responses.EDIT_TASK: response = edit_task ();
                                                    break;
                    case Responses.ABOUT: response = show_about ();
                                          break;
                    case Responses.NONE: response = main_menu ();
                                         break;
                    default: assert_not_reached ();
                }
            }

            show_good_bye();
        }

        private void show_welcome () {
            println ("Welcome to DoNotForget!");
        }

        private void show_good_bye () {
            println ("Thanks for using DoNotForget!");
        }

        private Responses show_about () {
            println ("This application was created with the intention to");
            println ("demonstrate Vala programming language features and");
            println ("techniques.");
            println ();
            println ("Author: Vratislav Podzimek");
            println ("email: vratislav.podzimek@gmail.com");
            println ("Please email me bug report, if you encounter bug.");
            println ();
            raw_input ("Hit ENTER to get back to main menu");

            return Responses.NONE;
        }

        private Responses main_menu () {
            println ("MAIN MENU:");
            println ("S -- show task collections");
            println ("A -- add task collection");
            println ("R -- remove task collection");
            println ("E -- edit task collection");
            println ("a -- add task");
            println ("r -- remove task");
            println ("e -- edit task");
            println ("---------------------------");
            println ("? -- show info about this program");
            println ("q -- quit DoNotForget");
            println ("===========================");
            var input = raw_input ("What would you like to do now?");
            if ((input.length < 1) || (!(input[0].to_string() in "SAREare?q")))
                return Responses.NONE;

            switch (input[0]) {
                case 'S': return Responses.SHOW_COLLECTIONS;
                case 'A': return Responses.ADD_COLLECTION;
                case 'R': return Responses.REMOVE_COLLECTION;
                case 'E': return Responses.EDIT_COLLECTION;
                case 'a': return Responses.ADD_TASK;
                case 'r': return Responses.REMOVE_TASK;
                case 'e': return Responses.EDIT_TASK;
                case '?': return Responses.ABOUT;
                case 'q': return Responses.QUIT;
            }

            return Responses.NONE;
        }

        private Responses show_collections () {
            foreach (var collection in _manager.collections) {
                println ("Collection '%s':".printf (collection.title));
                foreach (var task in collection)
                    println (@"$task");
                println ();
            }
            raw_input ("Hit ENTER to get back to main menu");

            return Responses.NONE;
        }

        private Responses add_collection () {
            var input = "";

            while (input == "") {
                input = raw_input ("Please enter the name of the new " +
                                   "collection:");
            }

            var collection = new GrowableTaskCollection (input);
            try {
                _manager.add_collection (collection);
            }
            catch (TaskManagerError e) {
                stderr.printf ("Failed to add collection '%s': %s\n",
                                collection.title, e.message);
            }
            input = raw_input("Do you want to add another collection? [y/N]");
            if (positive_answer (input))
                return Responses.ADD_COLLECTION;
            else
                return Responses.NONE;
        }

        private void show_available_collections () {
            println ("Available collections:");
            foreach (var collection in _manager.collections)
                println (collection.title);
            println ("===================================");
        }

        private string get_existing_collection_title (string prep = "") {
            show_available_collections ();
            string input = "";
            bool existing_collection = false;
            string question;

            if (prep != "")
                question = @"$prep which collection?";
            else
                question = "Which collection?";

            while (!existing_collection) {
                input = raw_input (question);
                existing_collection = _manager.has_collection (input);
            }

            return input;
        }

        private Responses remove_collection () {
            if (_manager.collections.size == 0) {
                println ("You need to add some collection first");
                return Responses.ADD_COLLECTION;
            }

            var title = get_existing_collection_title ();
            _manager.remove_collection_by_title (title);
            var input = raw_input ("Do you want to remove another collection? [y/N]");
            if (positive_answer (input))
                return Responses.REMOVE_COLLECTION;
            else
                return Responses.NONE;
        }

        private Responses edit_collection () {
            if (_manager.collections.size == 0) {
                println ("You need to add some collection first");
                return Responses.ADD_COLLECTION;
            }

            var title = get_existing_collection_title ();
            TaskCollection? collection = _manager[title];

            string input = "";
            do {
                input = raw_input ("Please enter the collection title:");
            }
            while (input == "");

            //FIXME: TaskManager needs a way to handle collections' titles
            //       changes
            _manager.remove_collection_by_title (collection.title);
            collection.title = input;
            try {
                _manager.add_collection (collection);
            }
            catch (TaskManagerError e) {
                stderr.printf ("Failed to add collection '%s'",
                                collection.title);
            }

            input = raw_input ("Do you want to edit another collection? [y/N]");
            if (positive_answer (input))
                return Responses.EDIT_COLLECTION;
            else
                return Responses.NONE;
        }

        private Responses add_task (TaskCollection? collection_arg = null) {
            if (_manager.collections.size == 0) {
                println ("You need to add collection first");
                return Responses.ADD_COLLECTION;
            }
            string title;
            TaskCollection? collection;

            if (collection_arg == null) {
                title = get_existing_collection_title ("To");
                collection = _manager[title];
                if (collection == null) {
                    return Responses.NONE;
                }
            }
            else {
                title = collection_arg.title;
                collection = collection_arg;
            }

            string task_desc = "";
            while (task_desc == "")
                task_desc = raw_input ("Enter the task description:");
            var completed_string = raw_input ("Is the task completed? " +
                                        "([y/N] or percentage of completion)");
            int completion = 0;
            Task new_task;
            if (positive_answer (completed_string))
                new_task = new Task.with_state (task_desc, true);
            else {
                try {
                    completion = checked_int_parse (completed_string);
                    new_task = new LongTimeTask.with_progress (task_desc,
                                            completion > 0 ? completion : 0);
                }
                catch (ParsingError e) {
                    new_task = new Task (task_desc);
                }
            }

            try {
                collection.add_task (new_task);
            }
            catch (TaskCollectionError e) {
                stderr.printf (@"Cannot add task '$new_task': %s", e.message);
            }

            var input = raw_input ("Do you want to add another task? [y/N]");
            if (positive_answer (input)) {
                input = raw_input ("To the same collection? [y/N]");
                if (positive_answer (input)) {
                    println ();
                    return add_task (collection);
                }
                else return Responses.ADD_TASK;
            }
            else
                return Responses.NONE;
        }

        private Task? get_task_choice (TaskCollection collection) {
            int num = 1;

            if (collection.number_of_tasks == 0) {
                return null;
            }

            foreach (var task in collection)
                println ("%2d) %s".printf (num++, task.description));

            num = 0;
            var task_number = "";
            while (num <= 0) {
                task_number = raw_input ("Enter the task number:");
                try {
                    num = checked_int_parse (task_number);
                }
                catch (ParsingError e) {
                    continue;
                }
            }

            Task? task = collection[num - 1];

            return task;
        }

        private Responses remove_task (TaskCollection? collection_arg = null) {
            if (_manager.collections.size == 0) {
                println ("You need to add collection first");
                return Responses.ADD_COLLECTION;
            }
            string title;
            TaskCollection? collection;

            if (collection_arg == null) {
                title = get_existing_collection_title ("From");
                collection = _manager[title];
                if (collection == null) {
                    return Responses.NONE;
                }
            }
            else {
                title = collection_arg.title;
                collection = collection_arg;
            }

            var task = get_task_choice (collection);
            if (task != null)
                collection.remove_task (task);
            else {
                println ("You need to add some task first");
                return add_task (collection);
            }

            var input = raw_input ("Do you want to remove another task? [y/N]");
            if (positive_answer (input)) {
                input = raw_input ("From the same collection? [y/N]");
                if (positive_answer (input)) {
                    println ();
                    return remove_task (collection);
                }
                else return Responses.REMOVE_TASK;
            }
            else
                return Responses.NONE;
        }

        private Responses edit_task (TaskCollection? collection_arg = null) {
            if (_manager.collections.size == 0) {
                println ("You need to add some collection first");
                return Responses.ADD_COLLECTION;
            }

            string title;
            TaskCollection? collection;

            if (collection_arg == null) {
                title = get_existing_collection_title ("From");
                collection = _manager[title];
                if (collection == null) {
                    return Responses.NONE;
                }
            }
            else {
                title = collection_arg.title;
                collection = collection_arg;
            }

            var task = get_task_choice (collection);
            if (task == null) {
                println ("You need to add some task first");
                return add_task (collection);
            }

            println (@"$task");

            var input = raw_input ("Enter new task description or just hit " +
                                   "ENTER to use the old one:");
            if (input != "")
                task.description = input;

            if (task is LongTimeTask) {
                var valid_input = false;

                while (!valid_input) {
                    input = raw_input ("Enter updated task progress:");
                    try {
                        var num = checked_int_parse (input);
                        LongTimeTask task2 = task as LongTimeTask;
                        task2.progress = num >= 0 ? num : 0;
                        valid_input = true;
                    }
                    catch (ParsingError e) {
                        continue;
                    }
                }
            }
            else {
                input = raw_input ("Is the collection now done? [y/N]");
                task.done = positive_answer (input);
            }

            input = raw_input ("Do you want to edit another task? [y/N]");
            if (positive_answer (input)) {
                input = raw_input ("From the same collection? [y/N]");
                if (positive_answer (input)) {
                    println ();
                    return edit_task (collection);
                }
                else return Responses.EDIT_TASK;
            }
            else
                return Responses.NONE;
        }

    }

}
