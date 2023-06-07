const int ButtonPin = 2;     // Push button pin, D2
const int OutputPin =  7;      // Output pin, D7

// Variable for reading the pushbutton status
int buttonState = 0;         

void setup() {
    // initialize the output pin as an output:
    pinMode(OutputPin, OUTPUT);
    // initialize the pushbutton pin as an input:
    pinMode(ButtonPin, INPUT);
}

void loop(){
    buttonState = digitalRead(ButtonPin);
    if (buttonState == HIGH) {
        digitalWrite(OutputPin, HIGH);
    }
    else {
        digitalWrite(OutputPin, LOW);
    }
}