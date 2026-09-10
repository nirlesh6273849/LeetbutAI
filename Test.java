import org.h2.Driver;
public class Test {
    public static void main(String[] args) {
        try {
            Class.forName("org.h2.Driver");
            System.out.println("H2 driver loaded");
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
