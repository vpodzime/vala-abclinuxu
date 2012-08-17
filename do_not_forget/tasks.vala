/**
   Basic class for tasks allowing storing task's description and state.
*/
class Task : GLib.Object {
	
	/* Private attributes */
	protected string desc;

	protected bool _done;

	/* Constructors */
	public Task (string desc) {
		this.desc = desc;
		this.done = false;
	}
	
	public Task.with_state (string desc, bool done) {
		this.desc = desc;
		this._done = done;
	}

	/* Properties */
	public string description {
		get { return desc; }
		set { desc = value; }
	}

	public virtual bool done {
		get { return _done; }
		set { _done = value; }
	}

	/* standard to_string() method that enables the @"$obj" functionality */
	public virtual string to_string() {
		var done_str = _done ? "done" : "not done";

		return @"$desc ($done_str)";
	}

}

/**
   Class inherited from the Task class adding the progress attribute

   @see Task
*/
class LongTimeTask : Task {

	private int _progress;

	/* Constructors */
	public LongTimeTask (string desc) {
		base(desc);
		_progress = 0;
	}
	
	public LongTimeTask.with_progress (string desc, int progress) {
		base(desc);
		this._progress = progress;
		this._done = (_progress == 100);
	}

	/* Property */
	public int progress {
		get { return _progress; }
		set {
			_progress = value;
			done = (value == 100);
		}
	}

	/* Override the done property to set the _progress attribute */
	public override bool done {
		get { return _done; }
		set {
			_done = value;
			_progress = value ? 0 : 100;
		}
	}

	public override string to_string() {
		var ret = base.to_string();

		return @"$ret [$progress]";
	}
	
}