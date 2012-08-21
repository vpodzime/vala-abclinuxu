using Tasks;

namespace TaskCollections {

    public errordomain TaskCollectionError {
        MAX_TASKS_LIMIT_EXCEEDED,
    }

    /**
        Abstract class for iterating over tasks. Every class implementing
        TaskCollection interface should have its own implementation of
        TasksIterator.
    */
    class TasksIterator : GLib.Object {

        private TaskCollection collection;
        private int position = -1;

        public TasksIterator (TaskCollection collection) {
            this.collection = collection;
        }

        public bool next () {
            if (collection.number_of_tasks > ++position)
                return true;
            else
                return false;
        }

        public new Task get () {
            return collection[position];
        }

    }


    /**
        Basic interface for collections of classes. Classes may implement their
        internal storage in various ways, but they need to implement this
        interfaces, so that they can be replaced with each other.
    */
    interface TaskCollection : GLib.Object {

        /* Methods for adding and removing tasks */
        public abstract void add_task (Task task) throws TaskCollectionError;
        public abstract void remove_task (Task task);

        /* Method making the indexing syntax for getting items work */
        public abstract Task? get (int index);

        /* Method making the 'in' operator work */
        public abstract bool contains (Task task);

        /**
           Method making the iteration work.
           Vala's interfaces can be used as mixins, so this method is not
           abstract and have its implementation in the interface code.
        */
        public TasksIterator iterator () {
            return new TasksIterator (this);
        }

        /* Properties */
        public abstract string title {
            get;
            set;
        }

        public abstract int number_of_tasks {
            get;
        }

        /* for debugging */
        public abstract string dump {
            owned get;
        }

    }


    /**
        Basic class implementing the TaskCollection interface. It uses
        fixed-size array as an internal storage.

        @see TaskCollection
    */
    class BasicTaskCollection : GLib.Object, TaskCollection {

        private static const int MAX_TASKS = 100;

        private Task[] tasks_array = new Task[MAX_TASKS];
        private string _title;

        /* helper variable for overflow checking and iterating*/
        private int tasks_top = -1;

        public BasicTaskCollection (string title) {
            _title = title;
        }

        public string title {
            get { return _title; }
            set { _title = value; }
        }

        public int number_of_tasks {
            get { return tasks_top + 1; }
        }

        public void add_task (Task task) throws TaskCollectionError {
            if (tasks_top + 1 < MAX_TASKS) {
                tasks_array[++tasks_top] = task;
            }
            else {
                throw new TaskCollectionError.MAX_TASKS_LIMIT_EXCEEDED(
                                     @"Max tasks limit ($MAX_TASKS) exceeded");
            }
        }

        public void remove_task (Task task) {
            int i = -1;
            bool found = false;

            /* find the task or go through the whole array */
            while ((i <= tasks_top) && !found) {
                i++;
                found = tasks_array[i] == task;
            }

            /* if task not found, just return (nothing to do) */
            if (!found) {
                return;
            }

            /* else remove the task (replace by null) */
            tasks_array[i] = null;

            /* and move the rest of the tasks to left */
            for (var j = i; j < tasks_top; j++) {
                tasks_array[j] = tasks_array[j+1];
            }

            /* finally, decrease the tasks_top value */
            tasks_top--;
        }

        public new Task? get (int index) 
            requires (index <= tasks_top)
        {
            if (index > tasks_top)
                return null;
            else
                return tasks_array[index];
        }

        public bool contains (Task task) {
            for (int i = 0; i <= tasks_top; i++) {
                if (tasks_array[i] == task)
                    return true;
            }
            return false;
        }

        public string dump {
            owned get {
                var ret = @"BasicTaskCollection '$_title':\n";
                for (int i = 0; i <= tasks_top ; i++) {
                    Task? task = this[i];
                    if (task == null)
                        ret += "**(null)**";
                    else
                        ret += task.to_string ();
                    ret += "\n";
                }

                return ret;
            }
        }

    }


    /**
        TaskCollection using automatically growing array as the internal
        storage.
    */
    class GrowableTaskCollection : GLib.Object, TaskCollection {

        private Task[] tasks_array = {};
        private string _title;

        public GrowableTaskCollection (string title) {
            _title = title;
        }

        public void add_task (Task task) {
            tasks_array += task;
        }

        public void remove_task (Task task) {
            int i = -1;
            bool found = false;

            /* find the task or go through the whole array */
            while ((i <= tasks_array.length) && !found) {
                i++;
                found = tasks_array[i] == task;
            }

            /* if task not found, just return (nothing to do) */
            if (!found) {
                return;
            }

            /* else remove the task (replace by null) */
            tasks_array[i] = null;

            /* and move the rest of the tasks to left */
            for (var j = i; j < (tasks_array.length - 1); j++) {
                tasks_array[j] = tasks_array[j+1];
            }

            /* finally, "shrink" the tasks_array */
            tasks_array.length--;
        }

        public new Task? get (int index)
            requires (index < tasks_array.length)
        {
            if (index >= tasks_array.length)
                return null;
            else
                return tasks_array[index];
        }

        public bool contains (Task task) {
            foreach (var cur_task in tasks_array) {
                if (task == cur_task)
                    return true;
            }

            return false;
        }

        public string title {
            get { return _title; }
            set { _title = value; }
        }

        public int number_of_tasks {
            get { return tasks_array.length; }
        }

        public string dump {
            owned get {
                var ret = @"TaskCollection '$_title':\n";
                foreach (var task in tasks_array)
                    ret += "%s\n".printf(task.to_string());

                return ret;
            }
        }

    }

}

