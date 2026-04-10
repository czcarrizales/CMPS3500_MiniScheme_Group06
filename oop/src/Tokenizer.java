
public class Tokenizer {
    public static String[] tokenize(String input) {
        input = input.replace("(", " ( ");
        input = input.replace(")", " ) ");
        return input.trim().split("\\s+");
    }
}



