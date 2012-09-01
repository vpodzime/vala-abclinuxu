using UserInterfaces;

class Application : GLib.Object {

    public static int main (string[] args) {
        var intf = new CommandLineInterface ();

        intf.run();

        return 0;
    }

}

