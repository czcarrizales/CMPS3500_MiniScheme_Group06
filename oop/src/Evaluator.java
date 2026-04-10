
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

	throw new RuntimeException("Not supported yet: ");
    }
}
	




