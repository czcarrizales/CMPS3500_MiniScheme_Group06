/*****************************************************************/
/* NAME: Stephanie Esquivel                                       */
/* ASGT: CMPS 3500 - MiniScheme OOP Implementation               */
/* FILE: MiniScheme.java                                         */
/*****************************************************************/


import java.io.*;
import java.nio.file.*;
import java.util.*;

//stores variables and their values 
//encapsulation, outside code cannot access bindings directly
class Environment {
	//encapsulating data 
	private Map<String, Object> bindings = new HashMap<>();
	private Environment parent;

	//constructor, reference to parent
	public Environment(Environment parent){
		this.parent = parent;
	}
	//public for evalautor 
	//name and value 
	public void define(String name, Object value){
		bindings.put(name, value);
	}

	//finding variable by name, if not found throw an exception
	public Object lookup(String name){
		if(bindings.containsKey(name)) {
			return bindings.get(name);
		}
		if (parent != null) {
			return parent.lookup(name);
		}
		throw new MSException("UNDECLARED_IDENTIFIER");
	}
} 
//exception, uses inheritance 
class MSException extends RuntimeException {
	public MSException(String message){
		super(message);
	}
}

//Expressions, this use polymorphism to run the right version depending on type
abstract class Expressions{

	//every sublclass must implement this abstract method
	public abstract Object evaluate(Environment env);

	//integer
	public static class Num extends Expressions {
		private int value;

		public Num(int value){
			this.value = value;
		}
		@Override
			public Object evaluate(Environment env){
				return value;
			}
	}	 

	//bool
	public static class Bool extends Expressions {
		private boolean value;

		public Bool(boolean value) {
			this.value = value;
		}	

		@Override
			public Object evaluate(Environment env) {
				return value;
			}
	}
	//variable
	public static class Var extends Expressions{
		private String name;

		public Var(String name){
			this.name = name;
		}

		@Override
			public Object evaluate(Environment env){		
				return env.lookup(name);
			}
	}
	//Primitive-built-in
	public static class Prim extends Expressions {
		public String op;

		public Prim(String op) {
			this.op = op;
		}

		@Override
			public Object evaluate(Environment env) {
				return op;
			}
	}
	//if condition
	public static class If extends Expressions {
		private Expressions condition;
		private Expressions then;
		private Expressions otherwise;

		public If(Expressions condition, Expressions then, Expressions otherwise) {
			this.condition = condition;
			this.then = then;
			this.otherwise = otherwise;
		}	

		@Override
			public Object evaluate(Environment env) {
				//evaluate condition
				Object condVal = condition.evaluate(env);
				//condition must be a boolean
				if (!(condVal instanceof Boolean)) {
					throw new MSException("TYPE_MISMATCH");
				}
				//evaluate and return the right branch
				if ((Boolean) condVal) {
					return then.evaluate(env);
				} else {
					return otherwise.evaluate(env);
				}
			}
	}
	//let 

	//lambda

	//add-on cond

	//define 
	public static class Define extends Expressions {
		private String name;
		private Expressions value;

		public Define(String name, Expressions value) {
			this.name = name;
			this.value = value;
		}
		@Override
			public Object evaluate(Environment env) {
				Object val = value.evaluate(env);
				env.define(name, val);
				return null;
			}
	}

	//function application
	public static class FunctionExpression extends Expressions {
		private Expressions function;
		private Expressions[] args;

		public FunctionExpression(Expressions function, Expressions[] args) {
			this.function = function;
			this.args = args;
		}
		@Override
			public Object evaluate(Environment env) {
				if (function instanceof Prim) {
					String op = ((Prim) function).op;
					return applyPrimitive(op, args, env);
				}
				throw new MSException("TYPE_MISMATCH");
			}

		private static Object applyPrimitive(String op, Expressions[] argExprs, Environment env) {
			//Arithmetic: +, -, *, 
			if (op.equals("+") || op.equals("-") || op.equals("*") || op.equals("/")) {
				int[] vals = evaluateInts(argExprs, env);
				switch (op) {
					case "+": {
							  int r = 0;
							  for (int v : vals) r += v;
							  return r;
						  }
					case "-": {
							  if (vals.length == 0) throw new MSException("WRONG_ARITY");
							  int r = vals[0];
							  for (int i = 1; i < vals.length; i++) r -= vals[i];
							  return r;
						  }
					case "*": {
							  int r = 1;
							  for (int v : vals) r *= v;
							  return r;
						  }
					case "/": {
							  if (vals.length == 0) throw new MSException("WRONG_ARITY");
							  int r = vals[0];
							  for (int i = 1; i < vals.length; i++) {
								  if (vals[i] == 0) throw new MSException("DIVISION_BY_ZERO");
								  r /= vals[i];
							  }
							  return r;
						  }
				}
			}

			// Comparisons: =, <, >, <=, >= (always take exactly 2 args)
			if (op.equals("=") || op.equals("<") || op.equals(">")
					|| op.equals("<=") || op.equals(">=")) {
				int[] vals = evaluateInts(argExprs, env);
				if (vals.length != 2) throw new MSException("WRONG_ARITY");
				switch (op) {
					case "=":  return vals[0] == vals[1];
					case "<":  return vals[0] <  vals[1];
					case ">":  return vals[0] >  vals[1];
					case "<=": return vals[0] <= vals[1];
					case ">=": return vals[0] >= vals[1];
				}
			}

			throw new MSException("TYPE_MISMATCH");
		}

		// Evaluate all arguments and return them as integers
		// Throws TYPE_MISMATCH if any argument is not an integer
		private static int[] evaluateInts(Expressions[] argExprs, Environment env) {
			int[] vals = new int[argExprs.length];
			for (int i = 0; i < argExprs.length; i++) {
				Object v = argExprs[i].evaluate(env);
				if (!(v instanceof Integer)) throw new MSException("TYPE_MISMATCH");
				vals[i] = (Integer) v;
			}
			return vals;
		}
	}
}

// TOKENIZER
// Converts raw input text into a list of tokens.
class Tokenizer {
	public static String[] tokenize(String input) {
		//comment lines
		StringBuilder sb = new StringBuilder();
		for (String line : input.split("\n")) {
			String trimmed = line.trim();
			if (!trimmed.startsWith(";")) {
				sb.append(trimmed).append(" ");
			}
		}
		String cleaned = sb.toString();

		//parentheses become separate tokens
		cleaned = cleaned.replace("(", " ( ");
		cleaned = cleaned.replace(")", " ) ");

		//Split on whitespace and filter empty strings
		String[] parts = cleaned.trim().split("\\s+");
		List<String> tokens = new ArrayList<>();
		for (String p : parts) {
			if (!p.isEmpty()) tokens.add(p);
		}
		return tokens.toArray(new String[0]);
	}
}

// PARSER
//Takes tokens from the Tokenizer 
class Parser {
	private String[] tokens;
	private int pos; 

	public Parser(String[] tokens) {
		this.tokens = tokens;
		this.pos = 0;
	}

	//parse all expressions in the input (a file can have many)
	public static List<Expressions> parseAll(String input) {
		String[] tokens = Tokenizer.tokenize(input);
		Parser p = new Parser(tokens);
		List<Expressions> exprs = new ArrayList<>();
		while (p.pos < p.tokens.length) {
			exprs.add(p.parseExpr());
		}
		return exprs;
	}

	//returns current token and advances position
	private String consume() {
		if (pos >= tokens.length) throw new MSException("PARSE_ERROR");
		return tokens[pos++];
	}

	//returns current token without advancing
	private String peek() {
		if (pos >= tokens.length) throw new MSException("PARSE_ERROR");
		return tokens[pos];
	}

	//check if there are tokens remaining
	private boolean hasMore() {
		return pos < tokens.length;
	}

	//parse one expression
	private Expressions parseExpr() {
		if (!hasMore()) throw new MSException("PARSE_ERROR");
		String tok = consume();

		//( means we are starting 
		if (tok.equals("(")) {
			if (!hasMore()) throw new MSException("PARSE_ERROR");
			String head = peek();

			//parse= (if condition then otherwise)
			if (head.equals("if")) {
				consume(); 
				Expressions cond = parseExpr();
				Expressions then = parseExpr();
				if (!hasMore() || peek().equals(")")) {
					throw new MSException("PARSE_ERROR");
				}
				Expressions otherwise = parseExpr();
				if (!hasMore() || !peek().equals(")")) {
					throw new MSException("PARSE_ERROR");
				}
				consume();
				return new Expressions.If(cond, then, otherwise);
			}

			//parse= define name value
			if (head.equals("define")) {
				consume(); 
				String name = consume();
				Expressions val = parseExpr();
				if (!peek().equals(")")) throw new MSException("PARSE_ERROR");
				consume(); 
				return new Expressions.Define(name, val);
			}

			//parse= any function call like 
			Expressions fn = parseExpr();
			List<Expressions> args = new ArrayList<>();
			while (!peek().equals(")")) {
				args.add(parseExpr());
			}
			consume(); 
			return new Expressions.FunctionExpression(fn, args.toArray(new Expressions[0]));
		}

		//boolean
		if (tok.equals("#t")) return new Expressions.Bool(true);
		if (tok.equals("#f")) return new Expressions.Bool(false);

		//operators
		if (tok.equals("+") || tok.equals("-") || tok.equals("*") || tok.equals("/")
				|| tok.equals("<") || tok.equals(">") || tok.equals("=")
				|| tok.equals("<=") || tok.equals(">=")) {
			return new Expressions.Prim(tok);
		}

		//integer 
		try { return new Expressions.Num(Integer.parseInt(tok)); }
		catch (NumberFormatException e) {}

		//variable name
		return new Expressions.Var(tok);
	}
}

// MAIN
//reads the .scm file, parses it, evaluates each expression,
public class MiniScheme {

	public static void main(String[] args) {
		if (args.length < 1) {
			System.err.println("Usage: java MiniScheme <file>");
			System.exit(1);
		}

		String filePath = args[0];
		String input;

		//read the .scm file
		try {
			input = new String(Files.readAllBytes(Paths.get(filePath)));
		} catch (IOException e) {
			System.out.println("FILE_NOT_FOUND");
			return;
		}

		//parsing into list
		List<Expressions> exprs;
		try {
			exprs = Parser.parseAll(input);
		} catch (MSException e) {
			System.out.println("PARSE_ERROR");
			return;
		} catch (Exception e) {
			System.out.println("PARSE_ERROR");
			return;
		}

		//create global environment
		Environment globalEnv = new Environment(null);

		//evaluate each expression -- result of last one is the output
		Object result = null;
		try {
			for (Expressions expr : exprs) {
				result = expr.evaluate(globalEnv); 
			}
		} catch (MSException e) {
			System.out.println(e.getMessage());
			return;
		} catch (Exception e) {
			System.out.println("TYPE_MISMATCH");
			return;
		}

		//printing result
		System.out.println(formatValue(result));
	}

	public static String formatValue(Object val) {
		if (val instanceof Boolean) return (Boolean) val ? "#t" : "#f";
		if (val == null) return "";
		return val.toString();
	}
}








