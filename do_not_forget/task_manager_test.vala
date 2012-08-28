using Tasks;
using TaskCollections;
using TaskManagerNS;

class TaskManagerTest : GLib.Object {

    public static int main (string[] args) {
        var manager = TaskManager.get_instance ();
        var manager2 = TaskManager.get_instance ();

        /* should not work. Uncomment to test.
        var manager3 = new TaskManager ();
        */

        if (manager == manager2)
            stdout.printf ("Only one instance of TaskManager => singleton\n");
        else
            stdout.printf ("Two instances of TaskManager!\n");

        TaskCollection collection = new BasicTaskCollection ("Personal");
        var task = new Task ("buy new helmet");
        try {
            collection.add_task (task);
        }
        catch (TaskCollectionError e) {
            stdout.printf (@"Failed to add '$task': %s\n", e.message);
        }

        task = new LongTimeTask ("test new helmet");
        try {
            collection.add_task (task);
        }
        catch (TaskCollectionError e) {
            stdout.printf (@"Failed to add '$task': %s\n", e.message);
        }

        try {
            manager.add_collection (collection);
        }
        catch (TaskManagerError e) {
            stdout.printf ("Failed to add collection '%s': %s", collection.title, e.message);
        }

        collection = new GrowableTaskCollection ("Work");
        task = new Task ("write patch for XY");
        try {
            collection.add_task (task);
        }
        catch (TaskCollectionError e) {
            stdout.printf (@"Failed to add '$task': %s\n", e.message);
        }

        task = new LongTimeTask ("write patch for YZ");
        try {
            collection.add_task (task);
        }
        catch (TaskCollectionError e) {
            stdout.printf (@"Failed to add '$task': %s\n", e.message);
        }

        try {
            manager.add_collection (collection);
        }
        catch (TaskManagerError e) {
            stdout.printf ("Failed to add collection '%s': %s", collection.title, e.message);
        }

        stdout.printf ("Collections in task manager:\n");
        foreach (var coll in manager.collections) {
            stdout.printf ("%s\n\n", coll.dump);
        }

        stdout.printf ("Removing collection '%s'\n", collection.title);
        manager.remove_collection_by_title (collection.title);
        stdout.printf ("Collections in task manager:\n");
        foreach (var coll in manager.collections) {
            stdout.printf ("%s\n\n", coll.dump);
        }

        stdout.printf ("Adding back\n");
        stdout.printf ("Collections in task manager:\n");
        try {
            manager.add_collection (collection);
        }
        catch (TaskManagerError e) {
            stdout.printf ("Failed to add collection '%s': %s", collection.title, e.message);
        }
        foreach (var coll in manager.collections) {
            stdout.printf ("%s\n\n", coll.dump);
        }

        return 0;
    }

}
