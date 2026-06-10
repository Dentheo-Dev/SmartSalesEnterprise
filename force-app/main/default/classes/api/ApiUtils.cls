public class ApiUtils {

    // Extrai Salesforce ID (15 ou 18 chars) do último segmento do URI
    public static String extractIdFromUri(String uri) {
        if (String.isBlank(uri)) {
            return null;
        }
        List<String> segments = uri.split('/');
        String last = segments[segments.size() - 1];
        return (last.length() == 15 || last.length() == 18) ? last : null;
    }
}
