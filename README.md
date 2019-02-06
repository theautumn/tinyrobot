# tinyrobot
A small set of Lua scripts for panel_gen and [nodeMCU](https://en.wikipedia.org/wiki/NodeMCU)

This provides a key and lamp so volunteers can start the [panel_gen](https://github.com/theautumn/panel_gen) demo during tours. The nodeMCU polls the key pin every 100ms, and polls the API every 1 sec. When the key is operated, a POST is made to the API, which starts the call generator. Another keypress turns it off.

![a key and lamp](https://i.imgur.com/2Pi5eqzl.jpg)
![a little enclosure](https://i.imgur.com/UDKUc5Cl.jpg)
![tub of butter substitute](https://imgur.com/g2UxMzql.jpg)
![different key and lamp](https://imgur.com/ZbwAk1cl.jpg)
