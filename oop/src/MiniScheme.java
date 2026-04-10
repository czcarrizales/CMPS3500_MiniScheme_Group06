public class MiniScheme {
	public static void main(String[] args) throws Exception {
		String input = FileLoaderStub.readFile(args[0]);

		String[] lines = input.split("\n");
		for (String line : lines) {
			line = line.trim();
			if (line.isEmpty()) {
				continue;
			}	
			Object result = Evaluator.evaluate(line);

			//bool
			if (result instanceof Boolean){
				System.out.println((Boolean) result ? "#t" : "#f");
			} else {
				System.out.println(result);

				//System.out.println("Input from file:\n" + input);	
			}
		}		
	}
}
