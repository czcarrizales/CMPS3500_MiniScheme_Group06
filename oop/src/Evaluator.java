
public class Evaluator{

	public static Object evaluate(String input){
		Expressions expr = Parser.parse(input);
		return eval(expr);
	}

	public static Object eval(Expressions expr){

		if (expr instanceof Expressions.Num){
			return ((Expressions.Num) expr).value;
		}
		if (expr instanceof Expressions.Bool){
			return ((Expressions.Bool) expr).value;
		}
		//function call
		if (expr instanceof Expressions.FunctionExpression) {
			Expressions.FunctionExpression app = (Expressions.FunctionExpression) expr;
			String op = ((Expressions.Prim) app.function).op;

			int left = (Integer) eval(app.args[0]);
			int right = (Integer) eval(app.args[1]);

			if (op.equals("+")) return left + right;
			if (op.equals("-")) return left - right;
			if (op.equals("*")) return left * right;
		}

		throw new RuntimeException("Not supported yet: ");
	}
}





