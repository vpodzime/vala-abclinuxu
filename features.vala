/* file features.vala */

namespace features
{
	/**
	 * Class for testing some of the Vala's features.
	 */
	class Features : GLib.Object
	{
		/**
		 * Private method facilitating input from user.
		 *
		 * @param prompt a prompt that would be appended with a newline and shown
		 * @return user's input
		 */
		private static string raw_input(string prompt)
		{
			string input;
			
			stdout.printf(prompt);
			input = stdin.read_line();

			return input;
		}

		/**
		 * Private method showing the constraints functionality.
		 *
		 * @param a one side of the rectangle
		 * @param b the other side
		 * @return rectangle's volume
		 */
		private static int rectangle_volume(int a, int b)
			requires (a >= 0 && b >= 0)
			ensures (result >= 0 && result == a * b)
		{
			return a * b;

			//try to comment out the previous return and uncomment the following one
			//return a * (-b);
		}
		
		/**
		 * Main method showing some of Vala's features one after another.
		 */
		public static int main(string[] args)
		{
			//use @"..." string and Vala will replace every $variable with its value
			string name = raw_input("Enter your name, please: ");
			stdout.printf(@"Hello $name, I'm a Vala program.\n\n");

			//test (experimental) regular expression literals
			string email = raw_input("Enter your email address, please: ");
			if (/^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}$/i.match(email))
			{
				stdout.printf("You have entered a valid email address.\n\n");
			}
			else
			{
				stdout.printf("You have entered an invalid email address.\n\n");
			}

			//use [i:j] for slicing
			string str = raw_input("Give me some at least 6 letters, I'll return you the second three of them: ");
			stdout.printf("Here they are: %s\n\n", str[3:6]);

			//objects can have properties
			Person person = new Person();
			//let's expect we really get a number, for now (otherwise the result will be 0)
			person.age = int.parse(raw_input("I've created a new person for you. Enter age, please: "));
			person.age++;
			stdout.printf("Incremented person's age: %d\n", person.age);
			stdout.printf("Person's weight: %d\n\n", person.weight);

			//use 'var' and let Vala deduce the type
			var person2 = new Person();
			person2.age = 42;
			person2.weight = 90;
			stdout.printf("Person2's age: %d\n", person2.age);
			stdout.printf("Person2's weight: %d\n\n", person2.weight);

			//use constraints in method definitions
			var a = int.parse(raw_input("Give me a length of a rectangle's side: "));
			var b = int.parse(raw_input("Give me the length of the other side: "));
			stdout.printf("Your rectangle's volume is: %d\n\n", rectangle_volume(a, b));

			//define get and set methods to enable object[index] syntax
			var street = raw_input("Enter street: ");
			var number = raw_input("Enter number: ");
			var city = raw_input("Enter city: ");
			var address = new Address(street, number, city);
			stdout.printf("Got: %s %s %s\n", address["street"], address["number"], address["city"]);
			address["number"] = "9999";
			stdout.printf("Changed to: %s %s %s\n", address["street"], address["number"], address["city"]);
			
			return 0;
		}
	}

	/**
	 * Class Person used for showing the properties functionality.
	 */
	class Person : GLib.Object
	{
		/**
		 * Property with default getter and setter and default value 0.
		 */
		public int age { get; set; }

		/**
		 * Property with default getter and setter and default value 80.
		 */
		public int weight { get; set; default=80; }
	}

	/**
	 * Class Address used for showing methods with syntax support functionality.
	 */
	class Address : GLib.Object
	{
		private string street;
		private string city;
		private string number;
		
		/**
		 * Constructor of the class Address.
		 *
		 * @param street A street
		 * @param number A number
		 * @param city A city
		 */
		public Address(string street, string number, string city)
		{
			this.street = street;
			this.number = number;
			this.city = city;
		}

		/**
		 * Method which enables the object[index] syntax.
		 *
		 * @param attr An attribute name
		 */
		//the method get is defined in the GLib.Object, so we have to use 'new' keyword to hide it
		public new string get(string attr)
		    requires (attr == "street" || attr == "number" || attr == "city")
		{
			//do not forget to put break or return at the end of cases
			switch (attr)
			{
			case "street": return this.street;
			case "number": return this.number;
			case "city": return this.city;
			default: return "";
			}
		}

		/**
		 * Method which enables the object[index] = value syntax.
		 *
		 * @param attr An attribute name
		 * @param value A value that should be assigned to the attribute
		 */
		//same reason for 'new' here as in case of the get method
		public new void set(string attr, string value)
		    requires (attr == "street" || attr == "number" || attr == "city")
		{
			switch (attr)
			{
			case "street":
			    this.street = value;
				return;
			case "number":
			    this.number = value;
				return;
			case "city":
			    this.city = value;
				return;
			default: return;
			}
		}
	}
}
