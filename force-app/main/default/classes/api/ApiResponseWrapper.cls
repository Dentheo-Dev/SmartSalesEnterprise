public class ApiResponseWrapper {

    public Boolean success;
    public Object  data;
    public String  error;
    public String  timestamp;

    private ApiResponseWrapper(Boolean success, Object data, String error) {
        this.success   = success;
        this.data      = data;
        this.error     = error;
        this.timestamp = DateTime.now().formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
    }

    public static ApiResponseWrapper ok(Object data) {
        return new ApiResponseWrapper(true, data, null);
    }

    public static ApiResponseWrapper fail(String errorMessage) {
        return new ApiResponseWrapper(false, null, errorMessage);
    }
}
