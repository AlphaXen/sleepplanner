#include <WiFiS3.h>
#include <Arduino_LED_Matrix.h>

ArduinoLEDMatrix matrix;

// -------------------------
// WiFi 정보
// -------------------------
const char* ssid = "SW_410_2.4G";
const char* password = "sunmoonsw410";

WiFiServer server(80);

// -------------------------
// RGB LED 핀 (Common Anode)
// -------------------------
const int PIN_R = 3;
const int PIN_G = 5;
const int PIN_B = 6;

int brightnessValue = 255;
bool powerState = false;
String colorMode = "daylight";

unsigned long lastReconnectAttempt = 0;

// ================== 3×5 숫자 폰트 ==================
uint8_t FONT3X5[10][5][3] = {
  { {1,1,1},{1,0,1},{1,0,1},{1,0,1},{1,1,1} }, // 0
  { {0,1,0},{1,1,0},{0,1,0},{0,1,0},{1,1,1} }, // 1
  { {1,1,1},{0,0,1},{1,1,1},{1,0,0},{1,1,1} }, // 2
  { {1,1,1},{0,0,1},{0,1,1},{0,0,1},{1,1,1} }, // 3
  { {1,0,1},{1,0,1},{1,1,1},{0,0,1},{0,0,1} }, // 4
  { {1,1,1},{1,0,0},{1,1,1},{0,0,1},{1,1,1} }, // 5
  { {1,1,1},{1,0,0},{1,1,1},{1,0,1},{1,1,1} }, // 6
  { {1,1,1},{0,0,1},{0,1,0},{0,1,0},{0,1,0} }, // 7
  { {1,1,1},{1,0,1},{1,1,1},{1,0,1},{1,1,1} }, // 8
  { {1,1,1},{1,0,1},{1,1,1},{0,0,1},{1,1,1} }  // 9
};

// -------------------------
// LED 매트릭스 숫자 표시
// -------------------------
void showThreeDigitNumber(int num) {
  if (num < 0) num = 0;
  if (num > 255) num = 255;

  int d1 = num / 100;
  int d2 = (num / 10) % 10;
  int d3 = num % 10;

  uint8_t buf[8][12] = {0};
  int yOffset = 1;

  for (int y=0; y<5; y++)
    for (int x=0; x<3; x++)
      buf[y+yOffset][x] = FONT3X5[d1][y][x];

  for (int y=0; y<5; y++)
    for (int x=0; x<3; x++)
      buf[y+yOffset][x+4] = FONT3X5[d2][y][x];

  for (int y=0; y<5; y++)
    for (int x=0; x<3; x++)
      buf[y+yOffset][x+8] = FONT3X5[d3][y][x];

  matrix.renderBitmap(buf, 8, 12);
}

//
// ========== RGB LED 제어 (공통 애노드 + 반전 PWM) ==========
//
void applyLED() {
  static int prevR = -1, prevG = -1, prevB = -1;

  if (!powerState) {
    analogWrite(PIN_R, 255);
    analogWrite(PIN_G, 255);
    analogWrite(PIN_B, 255);
    prevR = prevG = prevB = -1;
    return;
  }

  int r, g, b;

  if (colorMode == "daylight") {
    r = 255; g = 255; b = 200;
  } else {
    r = 255; g = 160; b = 80;
  }

  int safeBrightness = map(brightnessValue, 0, 255, 0, 180);

  r = (r * safeBrightness) / 255;
  g = (g * safeBrightness) / 255;
  b = (b * safeBrightness) / 255;

  int outR = 255 - r;
  int outG = 255 - g;
  int outB = 255 - b;

  if (outR == prevR && outG == prevG && outB == prevB) return;

  prevR = outR;
  prevG = outG;
  prevB = outB;

  analogWrite(PIN_R, outR);
  analogWrite(PIN_G, outG);
  analogWrite(PIN_B, outB);
}

// ================== DHCP 안정 대기 ==================
bool waitForDHCP(uint32_t timeoutMs = 5000) {
  uint32_t start = millis();
  while (millis() - start < timeoutMs) {
    if (WiFi.status() == WL_CONNECTED && WiFi.localIP() != IPAddress(0,0,0,0))
      return true;
    delay(200);
  }
  return false;
}

// ================== WiFi 자동 재연결 ==================
void ensureWiFi() {
  if (WiFi.status() == WL_CONNECTED && WiFi.localIP() != IPAddress(0,0,0,0))
    return;

  unsigned long now = millis();
  if (now - lastReconnectAttempt > 3000) {
    lastReconnectAttempt = now;

    WiFi.disconnect();
    WiFi.begin(ssid, password);

    if (waitForDHCP()) {
      showThreeDigitNumber(WiFi.localIP()[3]);
    }
  }
}

// ================== SETUP ==================
void setup() {
  Serial.begin(115200);

  pinMode(PIN_R, OUTPUT);
  pinMode(PIN_G, OUTPUT);
  pinMode(PIN_B, OUTPUT);

  matrix.begin();
  matrix.clear();

  WiFi.begin(ssid, password);
  Serial.println("Connecting...");

  if (!waitForDHCP(8000)) {
    matrix.clear();
    return;
  }

  Serial.print("IP: ");
  Serial.println(WiFi.localIP());
  showThreeDigitNumber(WiFi.localIP()[3]);

  server.begin();

  // ⭐ LED 기본 상태는 OFF
  powerState = false;
  applyLED();
}

// ================== LOOP ==================
void loop() {
  ensureWiFi();

  WiFiClient client = server.available();
  if (!client) return;

  String req = client.readStringUntil('\r');
  while (client.available()) client.read();
  client.flush();

  if (req.indexOf("/on") != -1) {
    powerState = true;
    applyLED();
  }

  if (req.indexOf("/off") != -1) {
    powerState = false;
    applyLED();
  }

  if (req.indexOf("/brightness") != -1) {
    int idx = req.indexOf("v=");
    if (idx != -1) {
      int newValue = req.substring(idx+2).toInt();
      newValue = constrain(newValue, 0, 255);

      if (abs(newValue - brightnessValue) > 1) {
        brightnessValue = newValue;
        applyLED();
      } else {
        brightnessValue = newValue;
      }
    }
  }

  if (req.indexOf("/color") != -1) {
    if (req.indexOf("daylight") != -1) colorMode = "daylight";
    if (req.indexOf("warm") != -1)     colorMode = "warm";
    applyLED();
  }

  client.println("HTTP/1.1 200 OK");
  client.println();
  client.println("OK");
  client.stop();
}
