using Tasks;

class TasksTest : GLib.Object {
    public static int main (string[] args) {
        Task task1 = new Task ("buy new helmet");
        var long_time = (task1 is LongTimeTask) ? "LongTimeTask" : "Task";
        stdout.printf("Added new %s: ", long_time);

        stdout.printf(@"$task1\n");

        Task task2 = new Task.with_state ("buy new helmet", true);
        long_time = (task2 is LongTimeTask) ? "LongTimeTask" : "Task";
        stdout.printf("Added new %s: ", long_time);

        stdout.printf(@"$task2\n");

        LongTimeTask task3 = new LongTimeTask.with_progress("test new helmet", 89);
        long_time = (task3 is LongTimeTask) ? "LongTimeTask" : "Task";
        stdout.printf("Added new %s: ", long_time);

        stdout.printf(@"$task3\n");

        return 0;
    }
}
