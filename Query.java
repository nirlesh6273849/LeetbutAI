import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;

public class Query {
    public static void main(String[] args) throws Exception {
        Class.forName("org.h2.Driver");
        Connection conn = DriverManager.getConnection("jdbc:h2:file:./data/pulse", "sa", "");
        Statement stmt = conn.createStatement();
        
        // List tables
        ResultSet rs = stmt.executeQuery("SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='PUBLIC'");
        System.out.println("Tables:");
        while (rs.next()) {
            System.out.println("  " + rs.getString("TABLE_NAME"));
        }
        
        // Now, let's try to get the user table if it exists
        // We'll try common table names: "USER", "USERS"
        String[] tableNames = {"USER", "USERS"};
        for (String tableName : tableNames) {
            try {
                rs = stmt.executeQuery("SELECT * FROM " + tableName);
                System.out.println("\nData from table " + tableName + ":");
                // Print column names
                for (int i = 1; i <= rs.getMetaData().getColumnCount(); i++) {
                    System.out.print(rs.getMetaData().getColumnName(i) + "\t");
                }
                System.out.println();
                // Print rows
                while (rs.next()) {
                    for (int i = 1; i <= rs.getMetaData().getColumnCount(); i++) {
                        System.out.print(rs.getString(i) + "\t");
                    }
                    System.out.println();
                }
            } catch (Exception e) {
                // Table might not exist or other error
                System.out.println("Could not query table " + tableName + ": " + e.getMessage());
            }
        }
        
        conn.close();
    }
}
