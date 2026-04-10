public abstract class Expressions{

	public static class Num extends Expressions{
		public int value;
		public Num(int value) { this.value = value; }
	}


	public static class Bool extends Expressions{
		public boolean value;
		public Bool(boolean value) { this.value = value; }
	}


	public static class Var extends Expressions{
		public String name;
		public Var(String name) { this.name = name; }
	}


	public static class Prim extends Expressions{
		public String op;
		public Prim(String op) { this.op = op; }
	}


	//if conditions

	//lambda

	//let

	//function call
	public static class FunctionExpression extends Expressions {
		public Expressions function;
		public Expressions[] args;
		public FunctionExpression(Expressions function, Expressions[] args) {
			this.function = function;
			this.args = args;
		}
	}

}



