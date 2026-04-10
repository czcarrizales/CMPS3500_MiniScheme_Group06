// Tiny file-loading helper stub for the OOP implementation.
import java.nio.file.Files;
import java.nio.file.Path;

public class FileLoaderStub {
    public static String readFile(String path) throws Exception {
        return Files.readString(Path.of(path));
    }
}
