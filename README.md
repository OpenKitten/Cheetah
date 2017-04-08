# Cheetah

A simple, yet fast JSON library. Developed for the OpenKitten ecosystem, it is created to feel like it belongs to the ecosystem as well as the programming language.

Cheetah's aim is to be a performant parser/serializer and to provide a good API.

## Usage

Import this dependency into your Package.swift 

`.Package(url: "https://github.com/OpenKitten/Cheetah.git", majorVersion: 1)`

Deserialize from UTF-8 bytes representing a JSON String:

```swift
let array = JSONArray(from: bytes)
let object = JSONObject(from: bytes)
```

Deserialize from a Swift String JSON:
```swift
let array = JSONArray(from: bytes)
let object = JSONObject(from: bytes)
```

Access values in an array like you would in Swift Arrays and values in an object like a Dictionary.

```swift
let favouriteNumber = favouriteNumbers[0]
let usernameValue = userObject["username"]
```

Extract types with simplicity:

```swift
let username = String(userObject["username"]) // "Joannis"
let isOnline = Bool(userObject["online"]) // true
let age = Int(userObject["age"]) // 20
let pi = Double(userObject["pi_constant"]) // 3.14
```

Chain subscripts easily to find results without a hassle as shown underneath:

```json
{
  "users": [
  	{
  		"username": "Joannis",
  		"profile": {
  		  "firstName": "Joannis",
  		  "lastName": "Orlandos"
  		}
  	},
  	{
  		"username": "Obbut",
  		"profile": {
  		  "firstName": "Robbert",
  		  "lastName": "Brandsma"
  		}
  	}
  ]
}
```

```swift
let obbutLastName = String(object["users"][1]["profile"]["lastName"]) // "Brandsma"
```

## Tutorials/info

[Tutorials and docs](http://docs.openkitten.org/tutorials/tutorials/cheetah/) are available among the rest.