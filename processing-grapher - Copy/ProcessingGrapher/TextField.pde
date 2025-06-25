class TextField {
  float x, y, w, h;
  String text = "";
  boolean isPassword;
  boolean isFocused = false;
  int cursorPosition = 0;
  long lastBlink = 0;
  boolean showCursor = true;
  
  TextField(float x, float y, float w, float h, boolean isPassword) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.isPassword = isPassword;
  }
  
  void draw() {
    // Draw field background
    stroke(c_sidebar_divider);
    fill(c_sidebar_button);
    rect(x, y, w, h);
    
    // Draw text
    fill(c_sidebar_text);
    textAlign(LEFT, CENTER);
    textFont(base_font);
    String displayText = isPassword ? new String(new char[text.length()]).replace("\0", "*") : text;
    
    // Clip text if it's too long
    String clippedText = displayText;
    while (textWidth(clippedText) > w - 10 && clippedText.length() > 0) {
      clippedText = clippedText.substring(1);
    }
    
    text(clippedText, x + 5, y + h/2);
    
    // Draw cursor when focused
    if (isFocused) {
      if (millis() - lastBlink > 500) {
        showCursor = !showCursor;
        lastBlink = millis();
      }
      if (showCursor) {
        float cursorX = x + 5 + textWidth(clippedText);
        stroke(c_sidebar_text);
        line(cursorX, y + 5, cursorX, y + h - 5);
      }
    }
  }
  
  boolean isMouseOver(int mx, int my) {
    return mx >= x && mx <= x + w && my >= y && my <= y + h;
  }
  
  void keyPressed() {
    if (!isFocused) return;
    
    if (key == BACKSPACE) {
      if (text.length() > 0 && cursorPosition > 0) {
        text = text.substring(0, cursorPosition - 1) + text.substring(cursorPosition);
        cursorPosition--;
      }
    } else if (key == DELETE) {
      if (text.length() > 0 && cursorPosition < text.length()) {
        text = text.substring(0, cursorPosition) + text.substring(cursorPosition + 1);
      }
    } else if (keyCode == LEFT) {
      cursorPosition = max(0, cursorPosition - 1);
    } else if (keyCode == RIGHT) {
      cursorPosition = min(text.length(), cursorPosition + 1);
    } else if (key >= ' ' && key <= '~' && key != TAB) {
      text = text.substring(0, cursorPosition) + key + text.substring(cursorPosition);
      cursorPosition++;
    }
  }
  
  String getText() {
    return text;
  }
  
  void setText(String newText) {
    text = newText;
    cursorPosition = text.length();
  }
  
  void setFocus(boolean focus) {
    isFocused = focus;
    if (focus) {
      cursorPosition = text.length();
    }
  }
}