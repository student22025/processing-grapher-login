class LoginManager {
  private boolean isLoggedIn = false;
  private HashMap<String, String> userCredentials;
  private String currentUserRole = "";
  
  LoginManager() {
    userCredentials = new HashMap<String, String>();
    // Add default admin and user credentials
    // Format: username:password:role
    addUser("admin", "admin123", "admin");
    addUser("user", "user123", "user");
  }
  
  void addUser(String username, String password, String role) {
    userCredentials.put(username, password + ":" + role);
  }
  
  boolean login(String username, String password) {
    if (userCredentials.containsKey(username)) {
      String[] stored = userCredentials.get(username).split(":");
      if (stored[0].equals(password)) {
        isLoggedIn = true;
        currentUserRole = stored[1];
        return true;
      }
    }
    return false;
  }
  
  boolean isAdmin() {
    return currentUserRole.equals("admin");
  }
  
  boolean isLoggedIn() {
    return isLoggedIn;
  }
  
  void logout() {
    isLoggedIn = false;
    currentUserRole = "";
  }
  
  String getCurrentRole() {
    return currentUserRole;
  }
}