/* file compile_test.vala */

//define our namespace
namespace compile_test
{

    /**
     * Example class showing Vala syntax and serving as an compile test.
     *
     * This class named CompileTest is inherited from the Object from GLib.
     */
    class CompileTest : GLib.Object
    {
        /**
         * The main method that is invoked when this program is run.
         *
         * @param args command line arguments
         */
        public static int main(string[] args)
        {
            //call method printf of the object stdout (standard output)
            stdout.printf("I have been successfully compiled and run.\n");
            return 0;
        }
    }

}
