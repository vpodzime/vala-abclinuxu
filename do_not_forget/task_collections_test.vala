using Tasks;
using TaskCollections;

class TaskCollectionsTest : GLib.Object {

    public static int main (string[] args) {
        var collection = new BasicTaskCollection ("Personal");

        var task1 = new Task ("buy new helmet");
        var task2 = new Task ("test new helmet");
        var task3 = new LongTimeTask.with_progress ("improve English", 10);

        try {
            collection.add_task (task1);
        }
        catch (TaskCollectionError e) {
            stdout.printf (@"Failed to add task '$task1': %s\n", e.message);
        }

        try {
            collection.add_task (task2);
        }
        catch (TaskCollectionError e) {
            stdout.printf (@"Failed to add task '$task2': %s\n", e.message);
        }

        try {
            collection.add_task (task3);
        }
        catch (TaskCollectionError e) {
            stdout.printf (@"Failed to add task '$task3': %s\n", e.message);
        }

        stdout.printf ("%s", collection.dump);

        stdout.printf (@"\nremoving task '$task2'\n\n");
        collection.remove_task (task2);

        stdout.printf("Tasks:\n");
        foreach (var task in collection) {
            stdout.printf(@"$task\n");
        }

        string in_not_in = (task2 in collection) ? "in" : "not in";
        stdout.printf (@"\nTask '$task2' $in_not_in collection\n");

        stdout.printf (@"\nadding task '$task2' back\n\n");
        try {
            collection.add_task (task2);
        }
        catch (TaskCollectionError e) {
            stdout.printf (@"Failed to add task '$task2': %s\n", e.message);
        }

        stdout.printf("Tasks:\n");
        foreach (var task in collection) {
            stdout.printf(@"$task\n");
        }

        return 0;

    }

}
