using TaskCollections;
using Tasks;
using Gee;

namespace TaskManagerNS {

    public errordomain TaskManagerError {
        COLLECTION_ALREADY_ADDED,
    }

    /**
        Class for a singleton object, that manages task collections.
    */
    class TaskManager : GLib.Object {

        private static TaskManager instance;

        private HashMap<string, TaskCollection> _collections;

        public static TaskManager get_instance () {
            instance = instance ?? new TaskManager ();
            return instance;
        }

        private TaskManager () {
            _collections = new HashMap<string, TaskCollection> ();
        }

        public void add_collection (TaskCollection collection)
            throws TaskManagerError 
        {
            var title = collection.title;

            if (title in _collections.keys)
                throw new TaskManagerError.COLLECTION_ALREADY_ADDED (
                                      @"Collection '$title' already added");

            _collections[title] = collection;
        }

        public void remove_collection (TaskCollection collection)
        {
            remove_collection_by_title (collection.title);
        }

        public void remove_collection_by_title (string title)
        {
            _collections.unset (title);
        }

        public new TaskCollection? get (string title) {
            if (title in _collections.keys)
                return _collections[title];
            else
                return null;
        }

        public bool has_collection (string title) {
            return title in _collections.keys;
        }

        public Collection<TaskCollection> collections {
            owned get { return _collections.values; }
        }

    }

}
