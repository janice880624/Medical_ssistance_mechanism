int PUL3 = A0;
int DIR3 = A1;
int ENA3 = A2;


int PUL2 = 10;
int DIR2 = 9;
int ENA2 = 8;

int PUL = 7;
int DIR = 12;
int ENA = 5;
int shi;

int PUL4 = 11;
int DIR4 = 13;    //8.25常數*乘時間
int ENA4 = 4;


int shz = 4730; //雷射和機械手臂在Z軸的相對位置

int shiy;
int she;

int shoy = 3100; //Z軸位移 (上下)

int dtl[30] = {440, 182, 140, 118, 104, 94, 86, 80, 75, 71, 68, 65, 62, 60, 58, 56, 54, 52, 51, 50, 49, 48, 47, 46, 45, 44, 43, 42, 41, 40};
int xtl[30] = {40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 54, 56, 58, 60, 62, 65, 68, 71, 75, 80, 86, 94, 104, 118, 140, 182, 440};

int ang = 0;
int sho = 0; //Y軸位移 (垂直輸送帶移動方向)
int shz2 = 0; //雷射和工件中心點在z軸的相對位置

#include <FastLED.h>
#define NUM_LEDS 16
#define DATA_PIN 39 //光源PIN
#define objdetect A4 //物件偵測PIN
#define stoploop 37 //停止按鈕PIN
CRGB leds[NUM_LEDS];
String datasend; //資料發送
String datareceive = ""; //資料接收的分配
String valuereceive[4];
int stopread; //讀取停止按鈕PIN值
void setup()
{
  pinMode(PUL2, OUTPUT);
  pinMode(DIR2, OUTPUT);
  pinMode(ENA2, OUTPUT);
  //  Serial.println(shiy);
  shiy = shoy - 2700 ;
  she = shiy + 2; //經校正的結果

  pinMode(PUL3, OUTPUT);
  pinMode(DIR3, OUTPUT);
  pinMode(ENA3, OUTPUT);

  pinMode(PUL, OUTPUT);
  pinMode(DIR, OUTPUT);
  pinMode(ENA, OUTPUT);
  pinMode(3, OUTPUT);
  pinMode(2, OUTPUT);

  pinMode(PUL4, OUTPUT);
  pinMode(DIR4, OUTPUT);
  pinMode(ENA4, OUTPUT);

  pinMode(A3, INPUT);

  FastLED.addLeds<WS2811, DATA_PIN, RGB>(leds, NUM_LEDS);
  pinMode(objdetect, INPUT_PULLUP);
  pinMode(stoploop, INPUT_PULLUP);
  digitalWrite(objdetect, LOW);
  Serial.begin(9600);
  Serial.setTimeout(3);
}
void loop()
{
  stopread = digitalRead(stoploop);
  shz2 = 0;
  sho = 0;
  ang = 0;
  while ( stopread == 1) {
    stopread = digitalRead(stoploop);
    if (stopread == 0) break;
    digitalWrite(DIR4, HIGH); //輸送帶
    digitalWrite(ENA4, HIGH); //輸送帶
    digitalWrite(PUL4, HIGH); //輸送帶
    delayMicroseconds(10);
    digitalWrite(PUL4, LOW); //輸送帶
    delayMicroseconds(790);
    if (digitalRead(A4) == HIGH) 
    {
      //偵測物件與讀取資料---
      for (int whiteLed = 0; whiteLed < NUM_LEDS; whiteLed = whiteLed + 1) {
        leds[whiteLed] = CRGB::White; //燈亮白光
        FastLED.show();
      }
      Serial.println("Object_detected"); //告知Matlab有物件經過要拍照
      delay(2000); //輛2秒關燈
      for (int whiteLed = 0; whiteLed < NUM_LEDS; whiteLed = whiteLed + 1) {
        leds[whiteLed] = CRGB::Black; //關燈
        FastLED.show();
      }
      int avai = Serial.available(); //avai:資料大小bytes
      //等待Matlab傳來的資料，有資料avai不為0
      while ( avai == 0) {
        stopread = digitalRead(stoploop);
        if (stopread == 0) {
          Serial.println("STOPLOOP");
          break;
        }
        avai = Serial.available();
      }
      int j=1;
      datareceive = Serial.readString(); //讀取Serial上的資料，也就是Matlab傳來的資料
      for (int i = 0; i < datareceive.length(); i++) {
        if (isSpace(datareceive[i])) {
          j++;
          continue;
        }
        valuereceive[j] += datareceive[i];
      }
      shz2 = valuereceive[1].toInt(); //X軸步數
      sho = valuereceive[2].toInt();  //Y軸步數
      ang = valuereceive[3].toInt();  //角度步數
      //裝配控制---
      for (int i = 0; i < shz; i++) //輸送帶(x軸)
      {
        digitalWrite(DIR4, HIGH);
        digitalWrite(ENA4, HIGH);
        digitalWrite(PUL4, HIGH);
        delayMicroseconds(10);
        digitalWrite(PUL4, LOW);
        delayMicroseconds(790);
        stopread = digitalRead(stoploop);
        if (stopread == 0) {
          Serial.println("STOPLOOP");
          break;
        }
      }
      for (int j = 0; j < shz2; j++) //輸送帶(x軸)
      {
        digitalWrite(DIR4, HIGH);
        digitalWrite(ENA4, HIGH);
        digitalWrite(PUL4, HIGH);
        delayMicroseconds(10);
        digitalWrite(PUL4, LOW);
        delayMicroseconds(790);
        stopread = digitalRead(stoploop);
        if (stopread == 0) {
          Serial.println("STOPLOOP");
          break;
        }
      }

      for (int i = 0; i < 30; i++)                           //Z軸下降加速
      {
        for (int j = 0; j < 30; j++)
        {
          digitalWrite(DIR2, LOW);
          digitalWrite(ENA2, HIGH);
          digitalWrite(PUL2, HIGH);
          delayMicroseconds(dtl[i]);
          digitalWrite(PUL2, LOW);
          delayMicroseconds(dtl[i]);
          stopread = digitalRead(stoploop);
          if (stopread == 0) {
            Serial.println("STOPLOOP");
            break;
          }
        }
        stopread = digitalRead(stoploop);
        if (stopread == 0) {
          Serial.println("STOPLOOP");
          break;
        }
      }
      for (int i = 0; i < shiy; i++)      //Z軸下降等速
      {
        digitalWrite(DIR2, LOW);
        digitalWrite(ENA2, HIGH);
        digitalWrite(PUL2, HIGH);
        delayMicroseconds(40);
        digitalWrite(PUL2, LOW);
        delayMicroseconds(40);
        stopread = digitalRead(stoploop);
        if (stopread == 0) {
          Serial.println("STOPLOOP");
          break;
        }
      }
      for (int i = 0; i < 30; i++)        //Z軸下降減速
      {
        for (int j = 0; j < 60; j++)
        {
          digitalWrite(DIR2, LOW);
          digitalWrite(ENA2, HIGH);
          digitalWrite(PUL2, HIGH);
          delayMicroseconds(xtl[i]);
          digitalWrite(PUL2, LOW);
          delayMicroseconds(xtl[i]);
          stopread = digitalRead(stoploop);
          if (stopread == 0) {
            Serial.println("STOPLOOP");
            break;
          }
        }
        stopread = digitalRead(stoploop);
        if (stopread == 0) {
          Serial.println("STOPLOOP");
          break;
        }
      }

      digitalWrite(2, HIGH);                              //幫樸開啟
      digitalWrite(3, LOW);
      delay(600);

      for (int i = 0; i < 30; i++)                        //Z軸上升
      {
        for (int j = 0; j < 30; j++)
        {
          digitalWrite(DIR2, HIGH);
          digitalWrite(ENA2, HIGH);
          digitalWrite(PUL2, HIGH);
          delayMicroseconds(dtl[i]);
          digitalWrite(PUL2, LOW);
          delayMicroseconds(dtl[i]);
          stopread = digitalRead(stoploop);
          if (stopread == 0) {
            Serial.println("STOPLOOP");
            break;
          }
        }
        stopread = digitalRead(stoploop);
        if (stopread == 0) {
          Serial.println("STOPLOOP");
          break;
        }
      }
      for (int i = 0; i < she; i++)
      {
        digitalWrite(DIR2, HIGH);
        digitalWrite(ENA2, HIGH);
        digitalWrite(PUL2, HIGH);
        delayMicroseconds(40);
        digitalWrite(PUL2, LOW);
        delayMicroseconds(40);
        stopread = digitalRead(stoploop);
        if (stopread == 0) {
          Serial.println("STOPLOOP");
          break;
        }
      }
      for (int i = 0; i < 30; i++)
      {
        for (int j = 0; j < 60; j++)
        {
          digitalWrite(DIR2, HIGH);
          digitalWrite(ENA2, HIGH);
          digitalWrite(PUL2, HIGH);
          delayMicroseconds(xtl[i]);
          digitalWrite(PUL2, LOW);
          delayMicroseconds(xtl[i]);
          stopread = digitalRead(stoploop);
          if (stopread == 0) {
            Serial.println("STOPLOOP");
            break;
          }
        }
        stopread = digitalRead(stoploop);
        if (stopread == 0) {
          Serial.println("STOPLOOP");
          break;
        }
      }

      for (int j = 0; j < ang; j++)           //轉角度
      {
        digitalWrite(DIR3, HIGH);
        digitalWrite(ENA3, HIGH);
        digitalWrite(PUL3, HIGH);
        delayMicroseconds(40);
        digitalWrite(PUL3, LOW);
        delayMicroseconds(40);
        stopread = digitalRead(stoploop);
        if (stopread == 0) {
          Serial.println("STOPLOOP");
          break;
        }
      }

      delay(1000);

      for (int i = 0; i < 30; i++)                      //y軸平移加速
      {
        for (int j = 0; j < 90; j++)
        {
          digitalWrite(DIR, LOW);
          digitalWrite(ENA, HIGH);
          digitalWrite(PUL, HIGH);
          delayMicroseconds(dtl[i]);
          digitalWrite(PUL, LOW);
          delayMicroseconds(dtl[i]);
          stopread = digitalRead(stoploop);
          if (stopread == 0) {
            Serial.println("STOPLOOP");
            break;
          }
        }
        stopread = digitalRead(stoploop);
        if (stopread == 0) {
          Serial.println("STOPLOOP");
          break;
        }
      }
      shi = sho - 5700;
      for (int i = 0; i < shi; i++)
      {
        digitalWrite(DIR, LOW);
        digitalWrite(ENA, HIGH);
        digitalWrite(PUL, HIGH);
        delayMicroseconds(40);
        digitalWrite(PUL, LOW);
        delayMicroseconds(40);
        stopread = digitalRead(stoploop);
        if (stopread == 0) {
          Serial.println("STOPLOOP");
          break;
        }
      }
      for (int i = 0; i < 30; i++)          //y軸平移減速
      {
        for (int j = 0; j < 100; j++)
        {
          digitalWrite(DIR, LOW);
          digitalWrite(ENA, HIGH);
          digitalWrite(PUL, HIGH);
          delayMicroseconds(xtl[i]);
          digitalWrite(PUL, LOW);
          delayMicroseconds(xtl[i]);
          stopread = digitalRead(stoploop);
          if (stopread == 0) {
            Serial.println("STOPLOOP");
            break;
          }
        }
        stopread = digitalRead(stoploop);
        if (stopread == 0) {
          Serial.println("STOPLOOP");
          break;
        }
      }

      for (int i = 0; i < 30; i++)                           //Z軸下降
      {
        for (int j = 0; j < 30; j++)
        {
          digitalWrite(DIR2, LOW);
          digitalWrite(ENA2, HIGH);
          digitalWrite(PUL2, HIGH);
          delayMicroseconds(dtl[i]);
          digitalWrite(PUL2, LOW);
          delayMicroseconds(dtl[i]);
          stopread = digitalRead(stoploop);
          if (stopread == 0) {
            Serial.println("STOPLOOP");
            break;
          }
        }
        stopread = digitalRead(stoploop);
        if (stopread == 0) {
          Serial.println("STOPLOOP");
          break;
        }
      }
      for (int i = 0; i < 30; i++)
      {
        for (int j = 0; j < 60; j++)
        {
          digitalWrite(DIR2, LOW);
          digitalWrite(ENA2, HIGH);
          digitalWrite(PUL2, HIGH);
          delayMicroseconds(xtl[i]);
          digitalWrite(PUL2, LOW);
          delayMicroseconds(xtl[i]);
          stopread = digitalRead(stoploop);
          if (stopread == 0) {
            Serial.println("STOPLOOP");
            break;
          }
        }
        stopread = digitalRead(stoploop);
        if (stopread == 0) {
          Serial.println("STOPLOOP");
          break;
        }
      }
      digitalWrite(2, LOW);                                    //幫浦關閉
      digitalWrite(3, LOW);
      delay(600);

      for (int i = 0; i < 30; i++)                               //Z軸上升
      {
        for (int j = 0; j < 30; j++)
        {
          digitalWrite(DIR2, HIGH);
          digitalWrite(ENA2, HIGH);
          digitalWrite(PUL2, HIGH);
          delayMicroseconds(dtl[i]);
          digitalWrite(PUL2, LOW);
          delayMicroseconds(dtl[i]);
          stopread = digitalRead(stoploop);
          if (stopread == 0) {
            Serial.println("STOPLOOP");
            break;
          }
        }
        stopread = digitalRead(stoploop);
        if (stopread == 0) {
          Serial.println("STOPLOOP");
          break;
        }
      }
      for (int i = 0; i < 30; i++)
      {
        for (int j = 0; j < 60; j++)
        {
          digitalWrite(DIR2, HIGH);
          digitalWrite(ENA2, HIGH);
          digitalWrite(PUL2, HIGH);
          delayMicroseconds(xtl[i]);
          digitalWrite(PUL2, LOW);
          delayMicroseconds(xtl[i]);
          stopread = digitalRead(stoploop);
          if (stopread == 0) {
            Serial.println("STOPLOOP");
            break;
          }
        }
        stopread = digitalRead(stoploop);
        if (stopread == 0) {
          Serial.println("STOPLOOP");
          break;
        }
      }
      for (int j = 0; j < ang; j++)           //轉回原本角度
      {
        digitalWrite(DIR3, LOW);
        digitalWrite(ENA3, HIGH);
        digitalWrite(PUL3, HIGH);
        delayMicroseconds(40);
        digitalWrite(PUL3, LOW);
        delayMicroseconds(40);
        stopread = digitalRead(stoploop);
        if (stopread == 0) {
          Serial.println("STOPLOOP");
          break;
        }
      }
      delay(1000);
      for (int i = 0; i < 30; i++)                          //Y軸平移
      {
        for (int j = 0; j < 90; j++)
        {
          digitalWrite(DIR, HIGH);
          digitalWrite(ENA, HIGH);
          digitalWrite(PUL, HIGH);
          delayMicroseconds(dtl[i]);
          digitalWrite(PUL, LOW);
          delayMicroseconds(dtl[i]);
          stopread = digitalRead(stoploop);
          if (stopread == 0) {
            Serial.println("STOPLOOP");
            break;
          }
        }
        stopread = digitalRead(stoploop);
        if (stopread == 0) {
          Serial.println("STOPLOOP");
          break;
        }
      }
      for (int i = 0; i < shi; i++)
      {
        digitalWrite(DIR, HIGH);
        digitalWrite(ENA, HIGH);
        digitalWrite(PUL, HIGH);
        delayMicroseconds(40);
        digitalWrite(PUL, LOW);
        delayMicroseconds(40);
        stopread = digitalRead(stoploop);
        if (stopread == 0) {
          Serial.println("STOPLOOP");
          break;
        }
      }
      for (int i = 0; i < 30; i++)
      {
        for (int j = 0; j < 100; j++)
        {
          digitalWrite(DIR, HIGH);
          digitalWrite(ENA, HIGH);
          digitalWrite(PUL, HIGH);
          delayMicroseconds(xtl[i]);
          digitalWrite(PUL, LOW);
          delayMicroseconds(xtl[i]);
          stopread = digitalRead(stoploop);
          if (stopread == 0) {
            Serial.println("STOPLOOP");
            break;
          }
        }
        stopread = digitalRead(stoploop);
        if (stopread == 0) {
          Serial.println("STOPLOOP");
          break;
        }
      }
      //
      Serial.println("DONE");
    }
    else
    {
      digitalWrite(DIR, LOW);
      digitalWrite(ENA, LOW);
      digitalWrite(PUL, LOW);
      digitalWrite(DIR2, LOW);
      digitalWrite(ENA2, HIGH);
      digitalWrite(PUL2, LOW);
    }
  }
  Serial.println("STOPLOOP");
  delay(100);
}
