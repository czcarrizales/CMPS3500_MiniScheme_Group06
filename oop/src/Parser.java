public class Parser{
	private String[] tokens;
	private int pos;

	public Parser(String[] tokens){
		this.tokens = tokens;
		this.pos = 0;
	}

	public static Expressions parse(String input){
		String[] tokens = Tokenizer.tokenize(input);
		return new Parser(tokens).parseExpr();
	}

	private String consume() { return tokens[pos++]; }
	private String peek() { return tokens[pos]; }


	private Expressions parseExpr() {
		String tok = consume();

		if (tok.equals("(")) {
			//if
			if (peek().equals("if")){
				consume();
				Expressions cond = parseExpr();
				Expressions then = parseExpr();
				Expressions otherwise = parseExpr();
				consume(); // eat )
				return new Expressions.If(cond, then, otherwise);
			}

			//function call
			Expressions fn = parseExpr();
			Expressions[] args = new Expressions[tokens.length];
			int count = 0;
			while (!peek().equals(")")) {
				args[count++] = parseExpr();
			}
			consume();  
			return new Expressions.FunctionExpression(fn, args);
		}

		if (tok.equals("#t")) return new Expressions.Bool(true);
		if (tok.equals("#f")) return new Expressions.Bool(false);
		
		if (tok.equals("+") || tok.equals("-") || tok.equals("*")
			|| tok.equals("<") || tok.equals(">") || tok.equals("="))
			return new Expressions.Prim(tok);

		try { return new Expressions.Num(Integer.parseInt(tok)); }
		catch (NumberFormatException e) {}

		return new Expressions.Var(tok);
	}
}





