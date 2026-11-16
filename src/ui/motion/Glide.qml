import QtQuick
import Iris

SpringAnimation {                       // settles without overshoot
    spring: Motion.spring * 1.3
    damping: 0.9
}