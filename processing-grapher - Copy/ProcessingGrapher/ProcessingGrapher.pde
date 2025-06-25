/* * * * * * * * * * * * * * * * * * * * * * *
 * PROCESSING GRAPHER
 *
 * @file     ProcessingGrapher.pde
 * @brief    A serial terminal and real-time graphing program for Arduino
 * @author   Simon Bluett
 * @website  https://wired.chillibasket.com/processing-grapher/
 * @version  1.7.0
 * @date     28th April 2024
 *
 * @license  GNU General Public License v3
 * @copyright Copyright (C) 2022 - Simon Bluett
 * * * * * * * * * * * * * * * * * * * * * * */

/*
 * Copyright (C) 2022 - Simon Bluett <hello@chillibasket.com>
 *
 * This file is part of ProcessingGrapher 
 * <https://github.com/chillibasket/processing-grapher>
 * 
 * ProcessingGrapher is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <https://www.gnu.org/licenses/>.
 */

import processing.serial.*;
import java.awt.event.KeyEvent;
import java.util.concurrent.locks.ReentrantLock;

// Login system variables
LoginManager loginManager;
TextField usernameField;
TextField passwordField;
boolean showLoginScreen = true;
boolean loginAttempted = false;
String loginErrorMessage = "";

// Serial communication
Serial serialPort;
String[] serialList;
String[] serialListNames;
boolean serialConnected = false;
boolean serialListUpdated = false;
int baudRate = 9600;
char lineEnding = '\n';
char serialParity = 'N';
int serialDatabits = 8;
float serialStopbits = 1.0;
char separator = ',';

// User interface
final String activeRenderer = FX2D;
PFont base_font;
PFont mono_font;
float uimult = 1.1;
int colorScheme = 1;
boolean drawFPS = false;
boolean showInstructions = true;
boolean settingsMenuActive = false;

// Tab system
TabAPI[] tabList;
int currentTab = 0;
String[] tabNames = {"Serial", "Live Graph", "File Graph"};
int tabHeight = 30;
int sidebarWidth = 200;
int bottombarHeight = 20;

// Drawing control
boolean redrawUI = true;
boolean redrawContent = true;
boolean drawNewData = false;
boolean startScrolling = false;
boolean scrollingActive = false;

// Color scheme variables
color c_background, c_tabbar, c_tabbar_h, c_idletab, c_tabbar_text, c_idletab_text;
color c_sidebar, c_sidebar_h, c_sidebar_heading, c_sidebar_text, c_sidebar_button;
color c_sidebar_divider, c_sidebar_accent, c_terminal_text, c_message_text;
color c_graph_axis, c_graph_gridlines, c_graph_border, c_serial_message_box;
color c_message_box_outline, c_alert_message_box, c_info_message_box;
color c_status_bar, c_highlight_background;

// Standard colors
final color c_white = color(255, 255, 255);
final color c_lightgrey = color(200, 200, 200);
final color c_grey = color(150, 150, 150);
final color c_darkgrey = color(100, 100, 100);
final color c_black = color(0, 0, 0);
final color c_red = color(255, 108, 160);
final color c_orange = color(255, 206, 84);
final color c_yellow = color(255, 255, 119);
final color c_green = color(168, 255, 119);
final color c_blue = color(119, 221, 255);
final color c_purple = color(187, 119, 255);
final color[] c_colorlist = {c_red, c_orange, c_yellow, c_green, c_blue, c_purple};

// UI sizing
int sideItemHeight = 22;

/**
 * Interface for tabs
 */
interface TabAPI {
  String getName();
  void setVisibility(boolean newState);
  void setMenuLevel(int newLevel);
  void drawContent();
  void drawNewData();
  void changeSize(int newL, int newR, int newT, int newB);
  void setOutput(String newoutput);
  String getOutput();
  void drawSidebar();
  void drawInfoBar();
  void keyboardInput(char keyChar, int keyCodeInt, boolean codedKey);
  void contentClick(int xcoord, int ycoord);
  void scrollWheel(float amount);
  void scrollBarUpdate(int xcoord, int ycoord);
  void menuClick(int xcoord, int ycoord);
  void parsePortData(String inputData, boolean graphable);
  void connectionEvent(boolean status);
  boolean checkSafeExit();
  void performExit();
}

/**
 * Setup function - runs once at the beginning
 */
void setup() {
  size(1000, 700);
  surface.setTitle("Processing Grapher v1.7.0");
  surface.setResizable(true);
  
  // Initialize login system
  loginManager = new LoginManager();
  usernameField = new TextField(width/2 - 100, height/2 - 50, 200, 30, false);
  passwordField = new TextField(width/2 - 100, height/2, 200, 30, true);
  
  // Load fonts
  try {
    base_font = createFont("Arial", round(11 * uimult));
    mono_font = loadFont("Inconsolata-SemiBold-11.vlw");
  } catch (Exception e) {
    println("Error loading fonts: " + e);
    base_font = createFont("Arial", round(11 * uimult));
    mono_font = createFont("Courier", round(11 * uimult));
  }
  
  // Load color scheme
  loadColorScheme(colorScheme);
  
  // Initialize tabs (but don't create them until logged in)
  tabList = new TabAPI[3];
  
  println("Processing Grapher v1.7.0 initialized");
}

/**
 * Initialize the main application after login
 */
void initializeApplication() {
  // Create tab instances
  int cL = 0;
  int cR = width - round(sidebarWidth * uimult);
  int cT = round(tabHeight * uimult);
  int cB = height - round(bottombarHeight * uimult);
  
  tabList[0] = new SerialMonitor("Serial", cL, cR, cT, cB);
  tabList[1] = new LiveGraph("Live Graph", cL, cR, cT, cB);
  tabList[2] = new FileGraph("File Graph", cL, cR, cT, cB);
  
  // Set initial tab visibility
  for (int i = 0; i < tabList.length; i++) {
    tabList[i].setVisibility(i == currentTab);
  }
  
  // Initialize serial port list
  updateSerialPortList();
  
  println("Application initialized successfully");
}

/**
 * Main draw loop
 */
void draw() {
  background(c_background);
  
  if (showLoginScreen) {
    drawLoginScreen();
  } else {
    drawMainApplication();
  }
}

/**
 * Draw the login screen
 */
void drawLoginScreen() {
  // Draw background
  fill(c_background);
  rect(0, 0, width, height);
  
  // Draw title
  textAlign(CENTER, CENTER);
  textFont(base_font);
  textSize(24);
  fill(c_sidebar_heading);
  text("Processing Grapher", width/2, height/2 - 120);
  
  textSize(16);
  fill(c_sidebar_text);
  text("Please login to continue", width/2, height/2 - 90);
  
  // Draw username label and field
  textAlign(LEFT, CENTER);
  textSize(12);
  fill(c_sidebar_text);
  text("Username:", width/2 - 100, height/2 - 70);
  usernameField.draw();
  
  // Draw password label and field
  text("Password:", width/2 - 100, height/2 - 20);
  passwordField.draw();
  
  // Draw login button
  fill(c_sidebar_button);
  stroke(c_sidebar_divider);
  rect(width/2 - 50, height/2 + 50, 100, 30);
  
  fill(c_sidebar_text);
  textAlign(CENTER, CENTER);
  text("Login", width/2, height/2 + 65);
  
  // Draw error message if login failed
  if (loginAttempted && !loginErrorMessage.equals("")) {
    fill(c_red);
    textAlign(CENTER, CENTER);
    text(loginErrorMessage, width/2, height/2 + 100);
  }
  
  // Draw default credentials info
  fill(c_grey);
  textAlign(CENTER, CENTER);
  textSize(10);
  text("Default: admin/admin123 or user/user123", width/2, height/2 + 130);
}

/**
 * Draw the main application interface
 */
void drawMainApplication() {
  if (redrawUI || redrawContent) {
    // Draw tab bar
    drawTabBar();
    
    // Draw current tab content
    if (tabList[currentTab] != null) {
      tabList[currentTab].drawContent();
    }
    
    // Draw sidebar
    drawSidebar();
    
    // Draw bottom info bar
    drawBottomBar();
    
    redrawUI = false;
    redrawContent = false;
  }
  
  // Draw new data if needed
  if (drawNewData && tabList[currentTab] != null) {
    tabList[currentTab].drawNewData();
    drawNewData = false;
  }
  
  // Draw FPS counter if enabled
  if (drawFPS) {
    fill(c_status_bar);
    textAlign(RIGHT, BOTTOM);
    textFont(mono_font);
    text(round(frameRate) + " fps", width - 5, height - 5);
  }
}

/**
 * Draw the tab bar
 */
void drawTabBar() {
  int tabWidth = (width - round(sidebarWidth * uimult)) / tabNames.length;
  int tabH = round(tabHeight * uimult);
  
  for (int i = 0; i < tabNames.length; i++) {
    int tabX = i * tabWidth;
    
    // Tab background
    if (i == currentTab) {
      fill(c_background);
      stroke(c_tabbar);
    } else {
      fill(c_idletab);
      stroke(c_tabbar);
    }
    
    rect(tabX, 0, tabWidth, tabH);
    
    // Tab text
    if (i == currentTab) {
      fill(c_tabbar_text);
    } else {
      fill(c_idletab_text);
    }
    
    textAlign(CENTER, CENTER);
    textFont(base_font);
    text(tabNames[i], tabX + tabWidth/2, tabH/2);
  }
}

/**
 * Draw the sidebar
 */
void drawSidebar() {
  int sidebarX = width - round(sidebarWidth * uimult);
  int sidebarY = round(tabHeight * uimult);
  int sidebarW = round(sidebarWidth * uimult);
  int sidebarH = height - sidebarY - round(bottombarHeight * uimult);
  
  // Sidebar background
  fill(c_sidebar);
  stroke(c_sidebar_divider);
  rect(sidebarX, sidebarY, sidebarW, sidebarH);
  
  // Draw current tab's sidebar content
  if (tabList[currentTab] != null) {
    tabList[currentTab].drawSidebar();
  }
}

/**
 * Draw the bottom information bar
 */
void drawBottomBar() {
  int barY = height - round(bottombarHeight * uimult);
  int barH = round(bottombarHeight * uimult);
  
  // Background
  fill(c_sidebar);
  stroke(c_sidebar_divider);
  rect(0, barY, width, barH);
  
  // Current user info
  fill(c_status_bar);
  textAlign(LEFT, CENTER);
  textFont(base_font);
  text("User: " + (loginManager.isAdmin() ? "Admin" : "User") + " | Role: " + loginManager.getCurrentRole(), 
       5, barY + barH/2);
  
  // Logout button
  fill(c_sidebar_button);
  stroke(c_sidebar_divider);
  rect(width - 60, barY + 2, 55, barH - 4);
  
  fill(c_sidebar_text);
  textAlign(CENTER, CENTER);
  text("Logout", width - 32, barY + barH/2);
  
  // Draw current tab's info bar content
  if (tabList[currentTab] != null) {
    tabList[currentTab].drawInfoBar();
  }
}

/**
 * Handle mouse clicks
 */
void mousePressed() {
  if (showLoginScreen) {
    handleLoginMouseClick();
  } else {
    handleMainApplicationMouseClick();
  }
}

/**
 * Handle mouse clicks on login screen
 */
void handleLoginMouseClick() {
  // Check username field
  if (usernameField.isMouseOver(mouseX, mouseY)) {
    usernameField.setFocus(true);
    passwordField.setFocus(false);
  }
  // Check password field
  else if (passwordField.isMouseOver(mouseX, mouseY)) {
    passwordField.setFocus(true);
    usernameField.setFocus(false);
  }
  // Check login button
  else if (mouseX >= width/2 - 50 && mouseX <= width/2 + 50 && 
           mouseY >= height/2 + 50 && mouseY <= height/2 + 80) {
    attemptLogin();
  }
  else {
    usernameField.setFocus(false);
    passwordField.setFocus(false);
  }
}

/**
 * Handle mouse clicks on main application
 */
void handleMainApplicationMouseClick() {
  int tabWidth = (width - round(sidebarWidth * uimult)) / tabNames.length;
  int tabH = round(tabHeight * uimult);
  int sidebarX = width - round(sidebarWidth * uimult);
  int bottomBarY = height - round(bottombarHeight * uimult);
  
  // Check tab clicks
  if (mouseY < tabH) {
    int clickedTab = mouseX / tabWidth;
    if (clickedTab >= 0 && clickedTab < tabNames.length && clickedTab != currentTab) {
      switchTab(clickedTab);
    }
  }
  // Check logout button
  else if (mouseX >= width - 60 && mouseX <= width - 5 && 
           mouseY >= bottomBarY + 2 && mouseY <= height - 2) {
    logout();
  }
  // Check sidebar clicks
  else if (mouseX >= sidebarX) {
    if (tabList[currentTab] != null) {
      tabList[currentTab].menuClick(mouseX, mouseY);
    }
  }
  // Check content area clicks
  else if (mouseY >= tabH && mouseY < bottomBarY) {
    if (tabList[currentTab] != null) {
      tabList[currentTab].contentClick(mouseX, mouseY);
    }
  }
}

/**
 * Attempt to login with current credentials
 */
void attemptLogin() {
  String username = usernameField.getText();
  String password = passwordField.getText();
  
  if (loginManager.login(username, password)) {
    showLoginScreen = false;
    initializeApplication();
    loginErrorMessage = "";
    redrawUI = true;
    redrawContent = true;
  } else {
    loginErrorMessage = "Invalid username or password";
    loginAttempted = true;
    passwordField.setText("");
  }
}

/**
 * Logout and return to login screen
 */
void logout() {
  loginManager.logout();
  showLoginScreen = true;
  loginAttempted = false;
  loginErrorMessage = "";
  usernameField.setText("");
  passwordField.setText("");
  usernameField.setFocus(false);
  passwordField.setFocus(false);
  
  // Clean up serial connection
  if (serialConnected) {
    disconnectSerial();
  }
  
  redrawUI = true;
  redrawContent = true;
}

/**
 * Switch to a different tab
 */
void switchTab(int newTab) {
  if (newTab >= 0 && newTab < tabList.length) {
    tabList[currentTab].setVisibility(false);
    currentTab = newTab;
    tabList[currentTab].setVisibility(true);
    redrawUI = true;
    redrawContent = true;
  }
}

/**
 * Handle keyboard input
 */
void keyPressed() {
  if (showLoginScreen) {
    handleLoginKeyInput();
  } else {
    handleMainApplicationKeyInput();
  }
}

/**
 * Handle keyboard input on login screen
 */
void handleLoginKeyInput() {
  if (key == ENTER || key == RETURN) {
    attemptLogin();
  } else if (key == TAB) {
    if (usernameField.isFocused) {
      usernameField.setFocus(false);
      passwordField.setFocus(true);
    } else {
      passwordField.setFocus(false);
      usernameField.setFocus(true);
    }
  } else {
    if (usernameField.isFocused) {
      usernameField.keyPressed();
    } else if (passwordField.isFocused) {
      passwordField.keyPressed();
    }
  }
}

/**
 * Handle keyboard input on main application
 */
void handleMainApplicationKeyInput() {
  // Global shortcuts
  if (keyCode == CONTROL || keyCode == META) {
    // Handle control key combinations in keyReleased
  } else if (tabList[currentTab] != null) {
    boolean codedKey = (key == CODED);
    tabList[currentTab].keyboardInput(key, keyCode, codedKey);
  }
}

/**
 * Handle mouse wheel scrolling
 */
void mouseWheel(MouseEvent event) {
  if (!showLoginScreen && tabList[currentTab] != null) {
    tabList[currentTab].scrollWheel(event.getCount());
  }
}

/**
 * Update serial port list
 */
void updateSerialPortList() {
  try {
    serialList = Serial.list();
    serialListNames = new String[serialList.length];
    for (int i = 0; i < serialList.length; i++) {
      serialListNames[i] = serialList[i];
    }
    serialListUpdated = true;
  } catch (Exception e) {
    println("Error updating serial port list: " + e);
    serialList = new String[0];
    serialListNames = new String[0];
  }
}

/**
 * Connect to serial port
 */
boolean connectSerial(String portName) {
  try {
    if (serialConnected) {
      disconnectSerial();
    }
    
    serialPort = new Serial(this, portName, baudRate, serialParity, serialDatabits, serialStopbits);
    serialPort.bufferUntil(lineEnding);
    serialConnected = true;
    
    // Notify all tabs of connection
    for (TabAPI tab : tabList) {
      if (tab != null) {
        tab.connectionEvent(true);
      }
    }
    
    println("Connected to serial port: " + portName);
    return true;
  } catch (Exception e) {
    println("Error connecting to serial port: " + e);
    serialConnected = false;
    return false;
  }
}

/**
 * Disconnect from serial port
 */
void disconnectSerial() {
  try {
    if (serialPort != null) {
      serialPort.stop();
      serialPort = null;
    }
    serialConnected = false;
    
    // Notify all tabs of disconnection
    for (TabAPI tab : tabList) {
      if (tab != null) {
        tab.connectionEvent(false);
      }
    }
    
    println("Disconnected from serial port");
  } catch (Exception e) {
    println("Error disconnecting from serial port: " + e);
  }
}

/**
 * Handle incoming serial data
 */
void serialEvent(Serial port) {
  if (!showLoginScreen && serialConnected) {
    try {
      String inputData = port.readStringUntil(lineEnding);
      if (inputData != null) {
        inputData = inputData.trim();
        
        // Check if data is graphable (contains numbers and separators)
        boolean graphable = isDataGraphable(inputData);
        
        // Send to all tabs
        for (TabAPI tab : tabList) {
          if (tab != null) {
            tab.parsePortData(inputData, graphable);
          }
        }
      }
    } catch (Exception e) {
      println("Error reading serial data: " + e);
    }
  }
}

/**
 * Check if data can be plotted on a graph
 */
boolean isDataGraphable(String data) {
  if (data == null || data.length() == 0) return false;
  
  String[] parts = data.split(String.valueOf(separator));
  if (parts.length < 1) return false;
  
  for (String part : parts) {
    try {
      Float.parseFloat(part.trim());
    } catch (NumberFormatException e) {
      return false;
    }
  }
  return true;
}

/**
 * Load color scheme
 */
void loadColorScheme(int mode) {
  switch (mode) {
    case 0: // Light mode - Celeste
      c_background = color(255, 255, 255);
      c_tabbar = color(229, 229, 229);
      c_tabbar_h = color(217, 217, 217);
      c_idletab = color(240, 240, 240);
      c_tabbar_text = color(50, 50, 50);
      c_idletab_text = color(140, 140, 140);
      c_sidebar = color(229, 229, 229);
      c_sidebar_h = color(217, 217, 217);
      c_sidebar_heading = color(34, 142, 195);
      c_sidebar_text = color(50, 50, 50);
      c_sidebar_button = color(255, 255, 255);
      c_sidebar_divider = color(217, 217, 217);
      c_sidebar_accent = color(255, 108, 160);
      c_terminal_text = color(136, 136, 136);
      c_message_text = c_grey;
      c_graph_axis = color(150, 150, 150);
      c_graph_gridlines = color(229, 229, 229);
      c_graph_border = c_graph_gridlines;
      c_serial_message_box = c_idletab;
      c_message_box_outline = c_tabbar_h;
      c_alert_message_box = c_tabbar;
      c_info_message_box = color(229, 229, 229);
      c_status_bar = c_message_text;
      c_highlight_background = c_tabbar;
      break;

    case 1: // Dark mode - One Dark Gravity
      c_background = color(40, 44, 52);
      c_tabbar = color(24, 26, 31);
      c_tabbar_h = color(19, 19, 28);
      c_idletab = color(33, 36, 43);
      c_tabbar_text = c_white;
      c_idletab_text = color(152, 152, 152);
      c_sidebar = color(24, 26, 31);
      c_sidebar_h = color(55, 56, 60);
      c_sidebar_heading = color(97, 175, 239);
      c_sidebar_text = c_white;
      c_sidebar_button = color(76, 77, 81);
      c_sidebar_divider = c_grey;
      c_sidebar_accent = c_red;
      c_terminal_text = color(171, 178, 191);
      c_message_text = c_white;
      c_graph_axis = c_lightgrey;
      c_graph_gridlines = c_darkgrey;
      c_graph_border = color(60, 64, 73);
      c_serial_message_box = c_idletab;
      c_message_box_outline = c_tabbar_h;
      c_alert_message_box = c_tabbar;
      c_info_message_box = c_tabbar;
      c_status_bar = c_terminal_text;
      c_highlight_background = color(61, 67, 80);
      break;

    case 2: // Dark mode - Monokai (default)
    default:
      c_background = color(40, 41, 35);
      c_tabbar = color(24, 25, 21);
      c_tabbar_h = color(19, 19, 18);
      c_idletab = color(32, 33, 28);
      c_tabbar_text = c_white;
      c_idletab_text = color(152, 152, 152);
      c_sidebar = c_tabbar;
      c_sidebar_h = c_tabbar_h;
      c_sidebar_heading = color(103, 216, 239);
      c_sidebar_text = c_white;
      c_sidebar_button = color(92, 93, 90);
      c_sidebar_divider = c_grey;
      c_sidebar_accent = c_red;
      c_terminal_text = c_lightgrey;
      c_message_text = c_white;
      c_graph_axis = c_lightgrey;
      c_graph_gridlines = c_darkgrey;
      c_graph_border = c_graph_gridlines;
      c_serial_message_box = c_darkgrey;
      c_message_box_outline = c_tabbar_h;
      c_alert_message_box = c_tabbar;
      c_info_message_box = c_darkgrey;
      c_status_bar = c_lightgrey;
      c_highlight_background = c_tabbar;
      break;
  }

  redrawUI = true;
  redrawContent = true;
}

/**
 * Handle window resize
 */
void windowResized() {
  if (showLoginScreen) {
    // Update login field positions
    usernameField = new TextField(width/2 - 100, height/2 - 50, 200, 30, false);
    passwordField = new TextField(width/2 - 100, height/2, 200, 30, true);
  } else {
    // Update tab sizes
    int cL = 0;
    int cR = width - round(sidebarWidth * uimult);
    int cT = round(tabHeight * uimult);
    int cB = height - round(bottombarHeight * uimult);
    
    for (TabAPI tab : tabList) {
      if (tab != null) {
        tab.changeSize(cL, cR, cT, cB);
      }
    }
  }
  
  redrawUI = true;
  redrawContent = true;
}

/**
 * Handle application exit
 */
void exit() {
  // Check if it's safe to exit
  boolean safeToExit = true;
  if (!showLoginScreen) {
    for (TabAPI tab : tabList) {
      if (tab != null && !tab.checkSafeExit()) {
        safeToExit = false;
        break;
      }
    }
  }
  
  if (safeToExit) {
    // Perform cleanup
    if (!showLoginScreen) {
      for (TabAPI tab : tabList) {
        if (tab != null) {
          tab.performExit();
        }
      }
    }
    
    if (serialConnected) {
      disconnectSerial();
    }
    
    super.exit();
  }
}

// Utility functions and helper methods would go here...
// (Include all the utility functions from the original file)

/**
 * UI resize function
 */
void uiResize() {
  uiResize(0);
}

void uiResize(float change) {
  if (change != 0) {
    uimult += change;
    if (uimult < 0.5) uimult = 0.5;
    if (uimult > 2.0) uimult = 2.0;
  }
  
  // Update fonts
  base_font = createFont("Arial", round(11 * uimult));
  
  // Update tab sizes if application is initialized
  if (!showLoginScreen && tabList[0] != null) {
    int cL = 0;
    int cR = width - round(sidebarWidth * uimult);
    int cT = round(tabHeight * uimult);
    int cB = height - round(bottombarHeight * uimult);
    
    for (TabAPI tab : tabList) {
      if (tab != null) {
        tab.changeSize(cL, cR, cT, cB);
      }
    }
  }
  
  redrawUI = true;
  redrawContent = true;
}

// Add other utility functions from the original ProcessingGrapher.pde file here...
// (Include functions like alertMessage, myShowInputDialog, etc.)

/**
 * Show alert message
 */
void alertMessage(String message) {
  println("Alert: " + message);
  // You can implement a proper dialog here if needed
}

/**
 * Show input dialog
 */
String myShowInputDialog(String title, String label, String defaultValue) {
  // Simple implementation - you can enhance this
  return defaultValue;
}

// Include other utility functions as needed...